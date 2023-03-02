my_threads = []
(1..2).each do |i|
  puts "Creating thread #{i}"
  my_threads << Thread.new(i) do |_j|
    loop do
      sleep(1)
      puts "work in #{Thread.current.object_id}"
    end
  end
end

loop do
  sleep(1)
  puts 'work in main thread'
end
