if Rails.env.production?
  Sidekiq.configure_server do |config|
    config.redis = {
      url: Rails.configuration.redis_url.to_s,
      network_timeout: 5,
      read_timeout: 1.0,
      write_timeout: 1.0
    }
  end

  Sidekiq.configure_client do |config|
    config.redis = {
      url: Rails.configuration.redis_url.to_s,
      network_timeout: 5,
      read_timeout: 1.0,
      write_timeout: 1.0
    }
  end
end
