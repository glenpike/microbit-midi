require 'serialport'
require 'json'
require "unimidi"

PORT = '/dev/cu.usbmodem1434402'
BAUD = 115200

serial = SerialPort.new(PORT, BAUD, 8, 1, SerialPort::NONE)

output = UniMIDI::Output.gets

def print_exception(exception, explicit)
  puts "[#{explicit ? 'EXPLICIT' : 'INEXPLICIT'}] #{exception.class}: #{exception.message}"
  puts exception.backtrace.join("\n")
end

def map180(value)
  ((value * 1.0 + 180) * ( 127.0 / 360.0)).to_i
end

midi_map = {
  cutoff: 16,
  resonance: 82,
  modulation: 1,
  overdrive: 114,
  distortion: 94
}

control_map = {
  roll: :cutoff,
  compass: :resonance,
  pitch: :distortion
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
        cc = midi_map[control]
        value = packet['v']
        
        puts "#{control} = #{cc} : #{value} = #{map180(value)}"
        output.puts(176, cc, value) 
      else
        if name.to_s == "input"
          puts "name! #{packet['v']}"
        # else
          # puts "name: #{name} packet #{packet}"
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
