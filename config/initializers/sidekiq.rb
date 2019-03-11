if Rails.env.production?
  Sidekiq.configure_server do |config|
    config.redis = redis_config
  end

  Sidekiq.configure_client do |config|
    config.redis = redis_config
  end
end

def redis_config
  {
    url: "rediss://#{Rails.configuration.redis_url}:6379",
    network_timeout: 5,
    password: Rails.configuration.redis_password,
    read_timeout: 1.0,
    write_timeout: 1.0
  }
end
