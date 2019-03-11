if Rails.env.production?
  Sidekiq.configure_server do |config|
    config.redis = {
      url: "rediss://#{Rails.configuration.redis_url}:6379",
      network_timeout: 5,
      password: Rails.configuration.redis_auth,
      read_timeout: 1.0,
      write_timeout: 1.0
    }
  end

  Sidekiq.configure_client do |config|
    config.redis = {
      url: "rediss://#{Rails.configuration.redis_url}:6379",
      network_timeout: 5,
      password: Rails.configuration.redis_auth,
      read_timeout: 1.0,
      write_timeout: 1.0
    }
  end
end
