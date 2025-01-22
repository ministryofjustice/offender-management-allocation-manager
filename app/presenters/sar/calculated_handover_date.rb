# frozen_string_literal: true

module Sar
  class CalculatedHandoverDate < BaseSarPresenter
    class << self
      def additional_methods
        [:reason, :responsibility]
      end
    end

    def reason
      reason_text
    end

    def responsibility
      responsibility_text
    end
  end
end
