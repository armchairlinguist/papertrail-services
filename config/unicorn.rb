worker_processes Integer(ENV["UNICORN_WORKERS"] || 3) # amount of unicorn workers to spin up

timeout 60 # restarts workers that hang for 60 seconds

preload_app true

before_fork do |server, worker|

  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end
end

after_fork do |server, worker|

  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end

  if $metriks_reporters && $metriks_reporters.is_a?(Array)
    $metriks_reporters.each do |reporter|
      reporter.restart
    end
  end
end