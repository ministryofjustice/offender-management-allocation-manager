# frozen_string_literal: true

module Sar
  class EmailHistory < BaseSarPresenter
    class << self
      def humanized_attributes
        [:event]
      end
    end
  end
end
