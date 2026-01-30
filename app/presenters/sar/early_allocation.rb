# frozen_string_literal: true

module Sar
  class EarlyAllocation < BaseSarPresenter
    class << self
      def omitted_attributes
        [:created_by_firstname, :created_by_lastname, :updated_by_firstname, :updated_by_lastname]
      end

      def humanized_attributes
        [:outcome]
      end
    end
  end
end
