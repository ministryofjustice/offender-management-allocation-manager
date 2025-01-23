# frozen_string_literal: true

module Sar
  class AuditEvent < BaseSarPresenter
    class << self
      def omitted_attributes
        [:data]
      end
    end
  end
end
