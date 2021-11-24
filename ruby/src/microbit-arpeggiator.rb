require 'serialport'
require 'json'
require 'unimidi'
require 'platform'
require 'diamond'

PORT_SEARCH = '/dev/cu.usbmodem*'

case Platform::IMPL
when :linux
  PORT_SEARCH = '/dev/ttyACM*'
when :mac
  PORT_SEARCH = '/dev/cu.usbmodem*'
end

files = Dir[PORT_SEARCH]

if files.length > 1
  printf "What port is your Microbit on?\nChoose a number\n\n"
  files.each_with_index do |f, index|
    printf "#{index + 1}: #{f}\n"
  end
  choice = gets
  choice = choice.chomp.to_i
  PORT = files[choice]
else
  PORT = files.first
end

printf "PORT: #{PORT}\n"

BAUD = 115_200

serial = SerialPort.new(PORT, BAUD, 8, 1, SerialPort::NONE)

UniMIDI::Output.all.each { |d| printf d.inspect.to_s }

output = UniMIDI::Output.gets

def print_exception(exception, explicit)
  printf "[#{explicit ? 'EXPLICIT' : 'INEXPLICIT'}] #{exception.class}: #{exception.message}\n"
  printf exception.backtrace.join("\n")
end

transpose = lambda { |value|
  input = [[value, 0].max, 100].min
  ((input.to_f / 101) * 8).to_i
}

note_map_1 = {
  pitch: { fn: transpose }
}

last_note = nil

id_map = {
  1_901_794_473 => {
    channel: 2,
    note_map: note_map_1,
    last_note: nil
  },
  1_689_304_789 => {
    channel: 1,
    note_map: note_map_1,
    last_note: nil
  }
}
id_map.each { |k, _v| printf "keys: '#{k}'\n" }
# printf "id map: #{id_map[1_689_304_789].inspect}\n"

options = {
  gate: 90,
  interval: 7,
  midi: output,
  pattern: 'UpDown',
  range: 2,
  rate: 16
}
arpeggiator = Diamond::Arpeggiator.new(options)
clock = Diamond::Clock.new(138)

clock << arpeggiator

chord = %w[C3 G3 E3]

arpeggiator.add(chord)
printf "starting clock\n"
clock.start(focus: true)

# Can't seem to use normal readline with threads as it blocks
# This appears to be a ruby / Mac OSX problem, (https://redmine.ruby-lang.org/issues/5539)
# but have installed readline with Brew and asdf ruby-build used this
# https://github.com/asdf-vm/asdf-ruby/pull/5
# Resolves problem, but we don't get any console output until we kill the program
def readline_nonblock(io)
  buffer = ''
  buffer << io.read_nonblock(1) while buffer[-1] != "\n"

  buffer
rescue IO::EAGAINWaitReadable
  IO.select([io])
  retry
end

def microbit_to_midi
  printf "poo\n"
  sleep 1
  true
  # line = readline_nonblock(serial)
  # packet = JSON.parse(line)
  # # byebug
  # name = packet['n']

  # controller = id_map[packet['s'].to_i]
  # # printf " controller for '#{packet['s'].to_i}': #{controller.inspect}\n"
  # return unless controller

  # note_map = controller[:note_map]
  # channel = controller[:channel] || 0
  # note = note_map[name.to_sym]
  # if note
  #   fn = note[:fn]
  #   value = fn.call(packet['v'])
  #   # printf "#{name} channel: #{channel} msg: #{0x90 + channel} note: #{packet['v']} = #{value}\n"
  #   # output.puts(0x80 + channel, controller[:last_note], 0) if controller[:last_note]
  #   if controller[:last_note] != value
  #     # printf "#{name} channel: #{channel} msg: #{0x90 + channel} note: #{packet['v']} = #{value}\n"
  #     # output.puts(0x90 + channel, value, 100)
  #     arpeggiator.transpose = value
  #     printf "arpeggiator.transpose #{arpeggiator.transpose}\n"
  #     controller[:last_note] = value
  #     clock.stop
  #     clock.start(focus: true)
  #   end

  # elsif name.to_s == 'input'
  #   printf "name! #{packet['v']}\n"
  #   # else
  #   #   printf "name: #{name} packet #{packet}\n"
  # end
end
@thread

begin
  @thread = Thread.new do
    loop { microbit_to_midi }
  rescue JSON::ParserError => e
    # printf "invalid packet: #{line}\n"
    next
  rescue NoMethodError
    printf "NoMethodError\n"
    next
  rescue Interrupt => e
    printf 'Thread interrupt?'
    Thread.main.raise(e)
  rescue StandardError => e
    printf 'Thread exception?'
    Thread.main.raise(e)
  end
  @thread.abort_on_exception = true
  @thread.run
rescue Interrupt => e
  print_exception(e, true)
rescue SignalException => e
  print_exception(e, false)
rescue StandardError => e
  print_exception(e, false)
ensure
  printf "stopping clock and joining thread\n"
  @thread.join
  clock.stop
end

id_map.each do |c|
  output.puts(0x80 + c[:channel], c[:last_note], 0) if c[:last_note]
end
