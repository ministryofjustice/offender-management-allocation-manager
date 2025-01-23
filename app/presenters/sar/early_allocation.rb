# frozen_string_literal: true

module Sar
  class EarlyAllocation < BaseSarPresenter
    class << self
      def humanized_attributes
        [:outcome]
      end
    end
  end
end
