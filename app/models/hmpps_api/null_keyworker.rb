# frozen_string_literal: true

module HmppsApi
  class NullKeyworker
    def initialize(msg)
      @message = msg
    end

    def full_name
      @message
    end

    class << self
      def api_error  = new('Data not available')
      def unassigned = new('None assigned')
    end
  end
end
