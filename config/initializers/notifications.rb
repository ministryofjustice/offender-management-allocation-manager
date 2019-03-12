# rubocop:disable Metrics/LineLength
# rubocop:disable Style/FormatStringToken
ActiveSupport::Notifications.subscribe('request.faraday') do |_name, start_time, end_time, _id, env|
  url = env[:url]
  http_method = env[:method].to_s.upcase
  duration = end_time - start_time
  Rails.logger.info '[%s] %s %s (%.3f s)' % [url.host, http_method, url.request_uri, duration]
end
# rubocop:enable Metrics/LineLength
# rubocop:enable Style/FormatStringToken
