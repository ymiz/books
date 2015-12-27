# -*- coding: utf-8 -*-
rails_root = File.expand_path('../../', __FILE__)

worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
timeout 15
preload_app true  # 更新時ダウンタイム無し

listen "#{rails_root}/tmp/sockets/unicorn.sock"
pid "#{rails_root}/tmp/pids/unicorn.pid"

before_fork do |server, worker|
  #Signal.trap 'TERM' do
   # puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
   # Process.kill 'QUIT', Process.pid
  #end

  defined?(ActiveRecord::Base) and
      ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
      rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) and
      ActiveRecord::Base.establish_connection
end

# ログの出力
stderr_path "#{rails_root}/log/unicorn_error.log"
stdout_path "#{rails_root}/log/unicorn.log"
