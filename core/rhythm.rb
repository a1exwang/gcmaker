require './core/signal_tools'

module GCMaker
  module Rhythm
    include SignalTools

    def frequency(f, windows, width, sample_rate)
      return nil if sample_rate <= 0 || f <= 0 || f >= sample_rate || width <= 0

      # These are the mathematical magic
      # Please refer to my sheet
      t = 1.0 / sample_rate
      n = width
      f1 = 1.0 / (n * t)
      i = (Float(f) / f1).ceil
      h = f1 * i - f
      m = ((h * n**2 * t) / (i - h*n*t)).round
      f_new = i / ((m + n) * t)

      ret = []
      windows.each_with_index do |window, index|
        # initialized to zero
        arr = NArray.float(window.size + m)
        j = 0
        window.each do |value|
          arr[j] = value
          j += 1
        end
        result = SignalTools.fft_window(window, width, sample_rate)
        ret[index] = result[:freqs][i]
      end
      { frequency: f_new, values: ret }
    end
  end
end