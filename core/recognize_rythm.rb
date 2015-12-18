require 'ruby-audio'
require 'json'
require 'fftw3'

MAX = 2 ** 31 - 1


def convert_from_wav(file_name)
  name = file_name.split('/').last.split('.')[0...-1].join
  s = RubyAudio::Sound.new(file_name, 'r', RubyAudio::SoundInfo.new(:channels => 1, :samplerate => 22500, :format => RubyAudio::FORMAT_WAV|RubyAudio::FORMAT_PCM_16))

  t = 1.0 / s.info.samplerate

  buf = s.read('int', s.info.frames)
  s.close

  [buf.map {|x| x}, 1.0 / s.info.samplerate, name, s.info.samplerate]
end

def convert_to_wav(file_name, data)
  s = RubyAudio::Sound.new(file_name, 'w', RubyAudio::SoundInfo.new(:channels => 1, :samplerate => 22500, :format => RubyAudio::FORMAT_WAV|RubyAudio::FORMAT_PCM_16))
  buf = RubyAudio::Buffer.new('int', data.size)
  data.size.times do |i|
    buf[i] = data[i]
  end
  s.write(buf)
  s.close
end

def save_to_json(data)
  json = data.to_json
  f = open('../graph.json', 'w')
  f.write json
  f.close
end

def to_mono(data)
  data.map do |item|
    if item.is_a?(Array)
      (item[0] + item[1]) / 2.0
    else
      item
    end
  end
end

def normalize(arr, max)
  sum = 0
  arr.each do |v|
    sum += v * v
  end
  average = Math.sqrt(sum / arr.size)
  average / max
end

def to_windows(arr, width, overlapping)
  offset = width - overlapping
  starts = Array.new(arr.size / offset) { |x| x * width }
  starts.map { |start| arr[start, offset] }
end

def disconnect(arr, width, overlapping = 0)
  windows = to_windows(arr, width, overlapping)
  ret = []
  windows.each do |w|
    normalized = normalize(w, @average)
    if normalized > 0.4
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

def make_interval(parts, interval)
  ret = []
  parts.each do |part|
    padding = part.count % interval
    ret += part
    ret += Array.new(padding, 0)
  end
  ret
end

def difference(arr)
  last = arr.first
  ret = []
  arr.each do |v|
    ret << v - last
    last = v
  end
  ret
end

def sample(arr, width)
  ret = []
  (arr.count / width).times do |x|
    ret << arr[x * width]
  end
  ret
end

freqs = [20, 40, 80, 160, 320, 500, 800, 1000, 1250, 1800, 2400, 3000, 5000, 8000, 10000, 20000]
def to_freqs(arr)
  na = NArray.float(1, arr.size)
  arr.each_with_index do |v, i|
    na[0, i] = v
  end

  freqs = FFTW3.fft(na, 1)
  ret = []
  freqs.each do |complex|
    ret << complex.magnitude
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

  #data = disconnect(data, 80 * @pts_per_millisec)

  window_size = 22.5 * 20
  windows = to_windows(data, window_size, 0)

  data = []
  windows.each do |window|
    freq = to_freqs(window)
    vpp = freq[2] / window.count
    data << (vpp > 400 ? vpp : 0)
  end
  m = Math.sqrt((data.inject { |sum, x| (sum ? sum : 0) + x * x }) / data.count)
  ret = []
  data.each_with_index do |x, index|
    (ret << { index: index, value: x }) if x > 2.5*m
  end
  puts ret
  # milliseconds per beat
  puts (1000.0 / sample_rate * window_size) * (ret.last[:index] - ret.first[:index]) / (ret.count - 2)
  # main
 # connected = data.inject do |sum, x|
 #   (sum.is_a?(Hash) ? [] : sum) +
 #       (x[:status] == :ok ? x[:data] : Array.new(x[:count], 0))
 # end
  #convert_to_wav("#{output_path}/#{name}_all.wav", connected)
  save_to_json(data)
  # # cut
  # merged = merge_disconnected(data)
  # merged.each_with_index do |d, i|
  #   convert_to_wav("#{output_path}/#{name}_#{i}.wav", d)
  # end

  # save
  #save_to_json(data)
end

@output_path = './output'
@input_file = 'music/unity_part1.wav'
# @input_folder = './source'
# Dir.entries(@input_folder).each do |entry|
#   puts entry + ' start!'
#   if !File.directory?(entry) && /\.wav$/.match(entry)
#     convert_my(@input_folder + '/' + entry, @output_path)
#   end
#   puts entry + ' done!'
# end

convert_my(@input_file, @output_path)