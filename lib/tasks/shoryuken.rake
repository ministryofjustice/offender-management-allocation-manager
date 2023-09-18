namespace :shoryuken do
  desc 'Start consuming domain events'
  task :start do # rubocop:disable Rails/RakeEnvironment
    exec('bundle', 'exec', 'shoryuken', '--rails', '-C', './config/shoryuken.yml')
  end
end
