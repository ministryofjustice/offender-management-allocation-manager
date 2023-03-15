class SentryCircuitBreakerService
  COUNT_KEY = 'sentry_request_count'.freeze
  LAST_RESET_KEY = 'sentry_request_count_last_reset'.freeze
  MONTHLY_QUOTA = 3_500_000
  MONTHLY_RESET_DAY = 14

  def self.check_within_quota(date: Time.zone.today)
    cache = redis_client

    if date.day == MONTHLY_RESET_DAY && cache.get(LAST_RESET_KEY) != date.to_s
      cache.set(COUNT_KEY, 0)
      cache.set(LAST_RESET_KEY, date.to_s)
    end

    cache.incr(COUNT_KEY)

    cache.get(COUNT_KEY).to_i <= MONTHLY_QUOTA
  end

private

  def self.redis_client
    if Rails.configuration.redis_url.present?
      Redis.new(url: Rails.configuration.redis_url.to_s)
    else
      Redis.new
    end
  end
end
