def build_redis_url
  if Rails.env.production?
    "rediss://:#{Rails.configuration.redis_auth}@#{Rails.configuration.redis_url}:6379/"
  end

  "redis://:#{Rails.configuration.redis_auth}@#{Rails.configuration.redis_url}:6379/"
end

if Rails.configuration.redis_url.present?
  require 'moneta'
  APICache.store = Moneta.new(:Redis, url: build_redis_url)
end
