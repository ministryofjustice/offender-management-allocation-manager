# frozen_string_literal: true

module HmppsApi
  class KeyworkerApi
    # See: https://keyworker-api-dev.prison.service.justice.gov.uk/swagger-ui/index.html#/Manage%20Allocations/getCurrentAllocation
    def self.get_keyworker(offender_no)
      client.get("/prisoners/#{offender_no}/allocations/current")
    rescue Faraday::Error => e
      Rails.logger.error(
        "nomis_offender_id=#{offender_no},event=keyworker_api_error|#{e.inspect},#{e.backtrace.join(',')}")
      nil
    end

    def self.client
      host = Rails.configuration.keyworker_api_host
      HmppsApi::Client.new(host)
    end
  end
end
