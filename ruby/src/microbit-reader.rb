require 'serialport'
require 'json'
require "unimidi"
require 'platform'

PORT_SEARCH = '/dev/cu.usbmodem*'

case Platform::IMPL
when :linux
  PORT_SEARCH = '/dev/ttyACM*'
when :mac
  PORT_SEARCH = '/dev/cu.usbmodem*'
end

files = Dir[PORT_SEARCH]

if files.length > 1
  puts "What port is your Microbit on?\nChoose a number\n"
  files.each_with_index do |f, index|
    puts "#{index + 1}: #{f}"
  end
  choice = gets
  choice = choice.chomp.to_i
  exit
  PORT = files[choice]
else
  PORT = files.first
end

puts "PORT: #{PORT}"

BAUD = 115200

serial = SerialPort.new(PORT, BAUD, 8, 1, SerialPort::NONE)

UniMIDI::Output.all.each { |d| puts "#{d.inspect}" }

output = UniMIDI::Output.gets

def print_exception(exception, explicit)
  puts "[#{explicit ? 'EXPLICIT' : 'INEXPLICIT'}] #{exception.class}: #{exception.message}"
  puts exception.backtrace.join("\n")
end

# -35 to 35
mapRoll = lambda { |value|
  min = -55
  max = 55
  offset = 180
  input = [value, min].max
  input = [input, max].min
  ((value.to_f + offset) * ( 127.0 / (max - min).to_f)).to_i
}

map180 = lambda { |value|
  ((value * 1.0 + 180) * ( 127.0 / 360.0)).to_i
}

map360 = lambda { |value|
  ((value * 1.0) * ( 127.0 / 360.0)).to_i
}

notes_1 = [36, 40, 43, 48, 52, 55, 60, 64, 67] # C E G arpeggios
notes_2 = [36, 38, 40, 41, 43, 45, 47, 48].map { |n| n + 24 }

mapNotes = lambda { |value, notes|
  input = [value, 0].max
  input = [input, 100].min
  index = ((input.to_f / 101) * notes.length).to_i
  notes[index]
}

midi_map = {
  cutoff: 74, #16,
  resonance: 71, #82,
  modulation: 1,
  overdrive: 114,
  distortion: 94
}

control_map_1 = {
  roll: { cc: :cutoff, fn: mapRoll },
  # compass: { cc: :distortion, fn: map360 },
}

control_map_2 = {
  roll: { cc: :cutoff, fn: mapRoll },
  # compass: { cc: :distortion, fn: map360 },
}

note_map_1 = {
  pitch: { fn: mapNotes, notes: notes_1 }
}

note_map_2 = {
  pitch: { fn: mapNotes, notes: notes_2 }
}

last_note = nil

id_map = {
  1901794473 => {
    channel: 0,
    note_map: note_map_1,
    control_map: control_map_1,
    last_note: nil
  },
  1689304789 => {
    channel: 1,
    note_map: note_map_2,
    control_map: control_map_2,
    last_note: nil
  }
}
id_map.each { |k, v| puts "keys: '#{k}'" }
puts "id map: #{id_map[1689304789].inspect}"

output.puts(0x91, 36, 100)
output.puts(0x92, 48, 100)
begin
  loop do
    line = serial.readline()
    begin
      packet = JSON.parse(line)
      # byebug
      name = packet['n']
      
      
      controller = id_map[packet['s'].to_i]
      # puts " controller for '#{packet['s'].to_i}': #{controller.inspect}"
      unless controller
        next
      end

      control_map = controller[:control_map]
      note_map = controller[:note_map]
      channel = controller[:channel] || 0
      control = control_map[name.to_sym]
      note = note_map[name.to_sym]
      if control
        cc = midi_map[control[:cc]]
        fn = control[:fn]
        value = fn.call(packet['v'])
        
        # puts "#{cc} (#{control[:cc]}) : #{packet['v']} = #{value}"
        output.puts(176 + channel, cc, value) 
      elsif note
        fn = note[:fn]
        value = fn.call(packet['v'], note[:notes])
        puts "#{name} channel: #{channel} msg: #{0x90 + channel} note: #{packet['v']} = #{value}"
        if controller[:last_note]
          output.puts(0x80 + channel, controller[:last_note], 0)
        end
        if controller[:last_note] != value
          output.puts(0x90 + channel, value, 100)
          controller[:last_note] = value
        end
        
      else
        if name.to_s == "input"
          puts "name! #{packet['v']}"
        # else
        #   puts "name: #{name} packet #{packet}"
        end
      end
    rescue JSON::ParserError => e
      puts "invalid packet: #{line}"
    rescue NoMethodError
      next
    end
  end
rescue Interrupt => e
  print_exception(e, true)
rescue SignalException => e
  print_exception(e, false)
rescue StandardError => e
  print_exception(e, false)
end

id_map.each do |c|
  if c[:last_note]
    output.puts(0x80 + c[:channel], c[:last_note], 0)
  end
end
