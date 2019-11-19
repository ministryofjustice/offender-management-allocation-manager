web: bundle exec rails db:migrate && bundle exec puma -p 3000 -C ./config/puma_prod.rb --pidfile /tmp/server.pid
worker: bundle exec sidekiq -C config/sidekiq.yml