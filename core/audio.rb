require 'ruby-audio'
require 'json'
require 'narray'
require './core/signal_tools'
require './core/rhythm'

module GCMaker
  class Audio
    attr_accessor :buffer
    attr_accessor :sample_rate

    include SignalTools
    include Rhythm

    def initialize(name, sound)
      @name = name
      @sound = sound

      # In millisecond
      @sample_period = 1000.0 / @sound.info.samplerate

      buf = @sound.read('int', @sound.info.frames)

      # initialize +@buffer+ with single dimension NArray
      @buffer = NArray.float(buf.size)
      buf.each_with_index do |item, index|
        @buffer[index] =
            item.is_a?(Array) ? (item[0] + item[1]) / 2.0 : item
      end
    end

    ##
    # Initialize from wave file
    def self.load_from(wave_file)
      # parse file name
      name = wave_file.split('/').last.split('.')[0...-1].join
      s = RubyAudio::Sound.new(
          wave_file, 'r',
          RubyAudio::SoundInfo.new(:format => RubyAudio::FORMAT_WAV | RubyAudio::FORMAT_PCM_16))
      Audio.new(name, s)
    end

    ##
    # Save to wave file
    def save_to(file_path)
      sound = RubyAudio::Sound.new(
          file_path,
          'w',
          RubyAudio::SoundInfo.new(channels: 1,
                                   samplerate: @sound.samplerate,
                                   format: RubyAudio::FORMAT_WAV | RubyAudio::FORMAT_PCM_16))
      buf = RubyAudio::Buffer.new('int', @buffer.size)
      @buffer.each do |v|
        buf[i] = v
      end
      sound.write(buf)
      sound.close
    end

    ##
    # Save to json file
    def save_to_json(file_path)
      temp_arr = Array.new(@buffer.size) { |x| @buffer[x] }
      json = {
          period: @sample_period,
          buffer: temp_arr.to_json
      }
      f = open(file_path, 'w')
      f.write(json)
      f.close
    end

    ##
    # Save to json file
    def self.save_to_json(curves, sample_rate, file_path)
      cs = []
      curves.each do |curve|
        cs.push(name: curve[:name], values: curve[:values].to_a)
      end

      json = {
          period: 1.0 / sample_rate,
          curves: cs
      }
      f = open(file_path, 'w')
      f.write(json.to_json)
      f.close
    end

  end
end