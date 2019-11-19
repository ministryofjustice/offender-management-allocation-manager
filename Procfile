web: bundle exec puma -C config/puma_prod.rb
worker: bundle exec sidekiq -c 5
release: bundle exec rails db:migrate
