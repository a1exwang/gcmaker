require 'fftw3'
require 'narray'


module GCMaker
  module SignalTools
    # Mathematical transformations

    def self.rms(buffer)
      Math.sqrt((buffer.inject { |sum, x| (sum ? sum : 0) + x * x }) / buffer.size)
    end

    ##
    # Root Mean Square of the buffer data
    def rms
      Math.sqrt((buffer.inject { |sum, x| (sum ? sum : 0) + x * x }) / buffer.size)
    end

    ##
    # Average
    def average
      buffer.sum / buffer.size
    end

    ##
    # Quick max
    def max
      @max ? @max : (@max = buffer.max)
    end

    ##
    # Quick min
    def min
      @min ? @min : (@min = buffer.min)
    end

    ##
    # Convert to dB
    def to_db
      buffer.map do |x|
        10 * Math.log10(x)
      end
    end
    ##
    # Convert to dB
    def to_db!
      self.buffer = buffer.map do |x|
        10 * Math.log10(x)
      end
    end

    ##
    # Convert to Energy
    def to_energy
      buffer.map do |x|
        x * x
      end
    end

    ##
    # Convert to Exp
    def to_exp
      buffer.map do |x|
        Math.exp(x)
      end
    end

    ##
    # Normalize with maximum value
    def normalize!
      buffer.map! do |x|
        x / max
      end
    end

    def self.normalize(buffer)
      max = 0
      buffer.each do |v|
        max = v if v > max
      end
      buffer.map do |x|
        x / max
      end
    end

    ##
    # Windowing function
    def window(width, overlapping = 0)
      offset = width - overlapping
      return nil unless offset > 0

      @window_width = width
      @window_overlapping = overlapping

      starts = Array.new(buffer.size / offset) { |x| x * width }
      @windows = starts.map { |start| buffer[start...(start+offset)] }
    end

    ##
    # Transform from time spectrum to frequency spectrum
    def frequencies(width)
      fft(@windows ? @windows : window(width), width, sample_rate)
    end

    ##
    # Sample
    def resample(width)
      ret = []
      (buffer.count / width).times do |x|
        ret << buffer[x * width]
      end
      ret
    end

    ##
    # Difference
    def difference
      last = buffer.first
      ret = []
      buffer.each do |v|
        ret << (v - last) * sample_rate
        last = v
      end
      ret
    end

    ##
    # Fast Fourier Transform for all windows
    # +width+ is the width of each window
    # +sample_rate+ is the sample rate of each window
    def self.fft(windows, width, sample_rate)
      ret = NArray.new(width, windows.size)
      f1 = sample_rate / width

      windows.each_with_index do |window, index|
        FFTW3.fft(window).each_with_index do |complex, row|
          ret[row, index] = complex.magnitude
        end
      end

      { f1: f1, freqs: ret }
    end

    def self.fft_window(window, width, sample_rate)
      ret = NArray.float(window.size)
      index = 0
      FFTW3.fft(window).each do |complex|
        ret[index] = complex.magnitude
        index += 1
      end
      f1 = sample_rate / width
      { f1: f1, freqs: ret }
    end
  end
end