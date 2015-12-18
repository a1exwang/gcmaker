require 'ruby-audio'
require 'json'
require 'fftw3'

MAX = 2 ** 31 - 1


def convert_from_wav(file_name)
  name = file_name.split('/').last.split('.')[0...-1].join
  s = RubyAudio::Sound.new(file_name, 'r', RubyAudio::SoundInfo.new(:channels => 1, :samplerate => 22050, :format => RubyAudio::FORMAT_WAV|RubyAudio::FORMAT_PCM_16))

  t = 1.0 / s.info.samplerate

  buf = s.read('int', s.info.frames)
  s.close

  [buf.map {|x| x}, 1.0 / s.info.samplerate, name, s.info.samplerate]
end

def convert_to_wav(file_name, data)
  s = RubyAudio::Sound.new(file_name, 'w', RubyAudio::SoundInfo.new(:channels => 1, :samplerate => 22050, :format => RubyAudio::FORMAT_WAV|RubyAudio::FORMAT_PCM_16))
  buf = RubyAudio::Buffer.new('int', data.size)
  data.size.times do |i|
    buf[i] = data[i]
  end
  s.write(buf)
  s.close
end

# +data+ value array
def save_to_json(data)
  json = data.to_json
  f = open('../graph.json', 'w')
  f.write json
  f.close
end

# stereo or mono to mono
def to_mono(data)
  data.map do |item|
    if item.is_a?(Array)
      (item[0] + item[1]) / 2.0
    else
      item
    end
  end
end

# +arr+ value array
# +max+ max
# arr ==> geometrical average / max
def normalize(arr, max)
  sum = 0
  arr.each do |v|
    sum += v * v
  end
  average = Math.sqrt(sum / arr.size)
  average / max
end

# +arr+ value array
# +width+ count of values in one window
# +overlapping+ overlapping between windows
def to_windows(arr, width, overlapping)
  offset = width - overlapping
  starts = Array.new(arr.size / offset) { |x| x * width }
  starts.map { |start| arr[start, offset] }
end

def disconnect(arr, width, overlapping = 0, threshold)
  windows = to_windows(arr, width, overlapping)
  ret = []
  windows.each do |w|
    normalized = normalize(w, @average)
    puts normalized
    if normalized > threshold
      ret << { status: :ok, data: w }
    else
      ret << { status: :no, count: w.size }
    end
  end
  ret
end

def merge_disconnected(arr)
  status = false
  ret = []
  current = []
  arr.each do |x|
    if status
      if x[:status] == :ok
        current += x[:data]
      else
        ret << current
        status = false
      end
    else
      if x[:status] == :ok
        current = []
        status = true
      end
    end
  end
  ret
end

# +parts+ value array
# +interval+ count of values in an interval
def make_interval(parts, interval)
  ret = []
  parts.each do |part|

    if part.count > interval
      ret += part.first(interval)
    else
      padding = interval - part.count
      ret += part
      ret += Array.new(padding, 0)
    end

  end
  ret
end

def convert_my(input_file, output_path)
  # prepare data
  data, t, name, sample_rate = convert_from_wav(input_file)
  data = to_mono(data)

  # transform
  @max = data.max
  @average = Math.sqrt((data.inject { |sum, x| (sum ? sum : 0) + x * x }) / data.size)
  @threshold = @max * 0.0707
  @pts_per_millisec = sample_rate / 1000

  data = disconnect(data, 20 * @pts_per_millisec, 0.1)

  # # main
  # connected = data.inject do |sum, x|
  #   (sum.is_a?(Hash) ? [] : sum) +
  #       (x[:status] == :ok ? x[:data] : Array.new(x[:count], 0))
  # end
  # convert_to_wav("#{output_path}/#{name}_all.wav", connected)
  #
  # # cut
  merged = merge_disconnected(data)
  merged.each_with_index do |d, i|
    convert_to_wav("#{output_path}/#{name}_#{i}.wav", d)
  end

  # with interval
  #data_intervaled = make_interval(merged, 278 * 2 * @pts_per_millisec)
  #convert_to_wav("#{output_path}/#{name}_rhythm.wav", data_intervaled)

  # save
  #save_to_json(data_intervaled)
end

@output_path = './output'
#@input_file = ARGV[0] || 'source/icraatd.wav'
@input_folder = './source'
Dir.entries(@input_folder).each do |entry|
  puts entry + ' start!'
  if !File.directory?(entry) && /\.wav$/.match(entry)
    convert_my(@input_folder + '/' + entry, @output_path)
  end
  puts entry + ' done!'
end

