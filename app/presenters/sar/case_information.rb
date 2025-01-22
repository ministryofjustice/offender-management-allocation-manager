# frozen_string_literal: true

module Sar
  class CaseInformation < BaseSarPresenter
    class << self
      def omitted_attributes
        [:ldu_code, :local_delivery_unit_id]
      end

      def additional_methods
        [:local_delivery_unit]
      end
    end

    def local_delivery_unit
      super.try(:name)
    end
  end
end
