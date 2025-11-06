# frozen_string_literal: true

class BankHolidays
  UnsuccessfulRetrievalError = Class.new(StandardError)

  API_URL = 'https://www.gov.uk/bank-holidays.json'
  DEFAULT_GROUP = 'england-and-wales'

  def self.dates(group = DEFAULT_GROUP) = new.dates(group)

  def dates(group = DEFAULT_GROUP)
    return [] if data.empty?

    dates = data.dig(group, 'events')&.pluck('date')
    dates.map { |date_string| Date.parse(date_string) }
  end

private

  def data
    @data ||= Rails.cache.fetch('bank-holidays', expires_in: 1.month) do
      response = Net::HTTP.get_response(URI.parse(API_URL))

      unless response.is_a?(Net::HTTPOK)
        raise UnsuccessfulRetrievalError, "Retrieval Failed: #{response.message} (#{response.code}) #{response.body}"
      end

      JSON.parse(response.body)
    end
  end
end
