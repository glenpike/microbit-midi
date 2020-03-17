require 'serialport'

PORT = '/dev/cu.usbmodem1431202'
BAUD = 115200

serial = SerialPort.new(PORT, BAUD, 8, 1, SerialPort::NONE)

def print_exception(exception, explicit)
  puts "[#{explicit ? 'EXPLICIT' : 'INEXPLICIT'}] #{exception.class}: #{exception.message}"
  puts exception.backtrace.join("\n")
end

begin
  loop do
    line = serial.readline()
    puts "line: #{line}"
  end
rescue Interrupt => e
  print_exception(e, true)
rescue SignalException => e
  print_exception(e, false)
rescue StandardError => e
  print_exception(e, false)
end
