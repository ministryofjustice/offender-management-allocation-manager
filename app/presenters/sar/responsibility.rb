# frozen_string_literal: true

module Sar
  class Responsibility < BaseSarPresenter
    class << self
      def humanized_attributes
        [:reason]
      end
    end
  end
end
