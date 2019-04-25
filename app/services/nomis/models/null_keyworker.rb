# frozen_string_literal: true

module Nomis
  module Models
    class NullKeyworker < KeyworkerDetails
      def full_name
        'Not assigned'
      end
    end
  end
end
