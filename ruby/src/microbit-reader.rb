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

map180 = lambda { |value|
  ((value * 1.0 + 180) * ( 127.0 / 360.0)).to_i
}

map360 = lambda { |value|
  ((value * 1.0) * ( 127.0 / 360.0)).to_i
}

midi_map = {
  cutoff: 74, #16,
  resonance: 71, #82,
  modulation: 1,
  overdrive: 114,
  distortion: 94
}

control_map = {
  roll: { cc: :cutoff, fn: map180 },
  compass: { cc: :resonance, fn: map360 },
  pitch: { cc: :distortion, fn: map180 }
}

begin
  loop do
    line = serial.readline()
    begin
      packet = JSON.parse(line)
      # byebug
      name = packet['n']

      control = control_map[name.to_sym]
      if control
        cc = midi_map[control[:cc]]
        fn = control[:fn]
        value = fn.call(packet['v'])
        
        puts "#{cc} (#{control[:cc]}) : #{packet['v']} = #{value}"
        output.puts(176, cc, value) 
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
