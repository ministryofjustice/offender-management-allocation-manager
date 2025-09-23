# frozen_string_literal: true

class KeyworkerService
  KEY_WORKER_CODE = 'KEY_WORKER'

  def self.get_keyworker(offender_no)
    response = HmppsApi::KeyworkerApi.get_keyworker(offender_no)
    return HmppsApi::NullKeyworker.api_error if response.nil?

    allocation = response.fetch('allocations', []).find do |alloc|
      alloc.dig('policy', 'code') == KEY_WORKER_CODE
    end
    return HmppsApi::NullKeyworker.unassigned if allocation.nil?

    HmppsApi::ApiDeserialiser.new.deserialise(
      HmppsApi::KeyworkerDetails, allocation
    )
  end
end
