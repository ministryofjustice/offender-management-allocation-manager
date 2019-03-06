def build_redis_url
  protocol = 'redis'
  protocol = 'rediss://' if Rails.env.production?

  "#{protocol}://#{Rails.configuration.redis_url}:6379/"
end

if Rails.configuration.redis_url.present?
  require 'moneta'
  APICache.store = Moneta.new(
    :Redis,
    url: build_redis_url,
    password: Rails.configuration.redis_auth,
    network_timeout: 5,
    read_timeout: 1.0,
    write_timeout: 1.0
  )
end
