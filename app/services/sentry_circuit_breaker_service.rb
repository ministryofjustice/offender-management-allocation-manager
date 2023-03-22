class SentryCircuitBreakerService
  COUNT_KEY = 'sentry_request_count'.freeze
  LAST_RESET_KEY = 'sentry_request_count_last_reset'.freeze
  LAST_WARN_KEY = 'sentry_request_count_last_warn'.freeze
  MONTHLY_QUOTA = 25_000
  MONTHLY_RESET_DAY = 14

  def self.check_within_quota(date: Time.zone.today)
    if date.day == MONTHLY_RESET_DAY && redis_client.get(LAST_RESET_KEY) != date.to_s
      redis_client.set(COUNT_KEY, 0)
      redis_client.set(LAST_RESET_KEY, date.to_s)
    end

    redis_client.incr(COUNT_KEY)

    if redis_client.get(COUNT_KEY).to_i > MONTHLY_QUOTA
      unless redis_client.get(LAST_WARN_KEY) == date.to_s
        Rails.logger = Logger.new($stdout) if Rails.env.production?

        Rails.logger.warn(
          "event=sentry_monthly_quota_exceeded|Sentry monthly error limit of #{MONTHLY_QUOTA} has been exceeded. " \
          "No more errors will be sent until day #{MONTHLY_RESET_DAY} of the month"
        )

        redis_client.set(LAST_WARN_KEY, date.to_s)
      end

      return false
    end

    true
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
