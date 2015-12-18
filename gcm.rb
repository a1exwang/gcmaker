require './core/audio'
require './core/rhythm'
require './core/signal_tools'
require './core/phoneme'
width = 45
sample_rate = 44100
@frequency = 100
freqs = [100]
audios = {
    part: GCMaker::Audio.load_from('resources/music/unity_part.wav'),
    part1: GCMaker::Audio.load_from('resources/music/unity_part1.wav')
}

curves = []

# audios.each do |name, audio|
#   windows = audio.window(width, 0)
#   buffer = audio.frequency(@frequency, windows, width, sample_rate)
#   curves.push(name: name, values: buffer[:values])
# end
freqs.each do |f|
  windows = audios[:part].window(width, 0)
  buffer = audios[:part].frequency(f, windows, width, sample_rate)
  curves.push(name: f.to_s, values: GCMaker::SignalTools.normalize(buffer[:values]))
end

GCMaker::Audio.save_to_json(curves, Float(sample_rate) / width, './visualizations/data/graph.json')