# frozen_string_literal: true

module Sar
  class OffenderEmailSent < BaseSarPresenter
    class << self
      def humanized_attributes
        [:offender_email_type]
      end
    end
  end
end
