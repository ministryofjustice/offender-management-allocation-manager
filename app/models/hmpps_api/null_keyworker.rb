# frozen_string_literal: true

module HmppsApi
  class NullKeyworker < KeyworkerDetails
    def full_name
      'Data not available'
    end
  end
end
