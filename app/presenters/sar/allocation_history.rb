# frozen_string_literal: true

module Sar
  class AllocationHistory < BaseSarPresenter
    class << self
      def omitted_attributes
        [
          :primary_pom_name,
          :secondary_pom_name,
          :primary_pom_nomis_id,
          :secondary_pom_nomis_id,
          :created_by_name,
        ]
      end

      def humanized_attributes
        [:event, :event_trigger]
      end

      def additional_methods
        [:override_reasons]
      end
    end

    def override_reasons
      super.first.try(:humanize) if super.is_a?(Array)
    end
  end
end
