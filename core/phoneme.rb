require './core/signal_tools'
require 'narray'

module GCMaker
  module Phoneme
    include SignalTools

    ##
    # Divide the buffer by volume
    def divide(width, overlapping, rms_threshold)
      windows = window(width, overlapping)

      status = false
      ret, offset = NArray.new(buffer.size), 0
      current = []
      windows.each do |w|
        r = SignalTools.rms(w)
        if status
          if r > rms_threshold
            current += w.to_a
          else
            ret[offset...(offset+current.size)] = current
            offset += current.size
            status = false
          end
        else
          if r > rms_threshold
            current = w.to_a
            status = true
          end
        end
      end
      ret
    end

    # +parts+ value array
    # +interval+ count of values in an interval
    # +fixed+ truncate if parts[i].size > interval
    def make_interval(parts, interval, fixed = false)
      ret = []
      parts.each do |part|
        if part.size > interval
          if fixed
            ret += part[0...interval].to_a
          else
            ret += part.to_a
            padding = interval - part.size % interval
            ret += [0] * padding
          end
        else
          padding = interval - part.size
          ret += part.to_a
          ret += [0] * padding
        end
      end

      # convert to narray
      narray = NArray.int(ret.size)
      ret.size.times do |x|
        narray[x] = ret[x]
      end
      narray
    end
  end
end