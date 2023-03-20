class SentryCircuitBreakerService
  COUNT_KEY = 'sentry_request_count'.freeze
  LAST_RESET_KEY = 'sentry_request_count_last_reset'.freeze
  MONTHLY_QUOTA = 25_000
  MONTHLY_RESET_DAY = 14

  def self.check_within_quota(date: Time.zone.today)
    if date.day == MONTHLY_RESET_DAY && redis_client.get(LAST_RESET_KEY) != date.to_s
      redis_client.set(COUNT_KEY, 0)
      redis_client.set(LAST_RESET_KEY, date.to_s)
    end

    redis_client.incr(COUNT_KEY)

    redis_client.get(COUNT_KEY).to_i <= MONTHLY_QUOTA
  end

private

  def self.redis_client
    @redis_client ||= if Rails.configuration.redis_url.present?
                        Redis.new(url: Rails.configuration.redis_url.to_s)
                      else
                        Redis.new
                      end
  end
end
