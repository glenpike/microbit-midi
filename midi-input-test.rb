require 'unimidi'

@input = UniMIDI::Input.gets

def print_exception(exception, explicit)
  puts "[#{explicit ? 'EXPLICIT' : 'INEXPLICIT'}] #{exception.class}: #{exception.message}"
  puts exception.backtrace.join("\n")
end

begin
  loop do
    midi = @input.gets
    puts "midi: #{midi}"
    sleep(0.1)
  end
rescue Interrupt => e
  print_exception(e, true)
rescue SignalException => e
  print_exception(e, false)
rescue StandardError => e
  print_exception(e, false)
end
