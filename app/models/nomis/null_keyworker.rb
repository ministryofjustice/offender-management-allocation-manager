# frozen_string_literal: true

module Nomis
  class NullKeyworker < KeyworkerDetails
    def full_name
      'Data not available'
    end
  end
end
