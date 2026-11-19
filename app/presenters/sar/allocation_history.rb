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
          :primary_pom_reviewed_at,
          :reviewed_recommended_pom_type,
        ]
      end

      def humanized_attributes
        [:event, :event_trigger, :recommended_pom_type]
      end

      def additional_methods
        [:created_by_lastname, :override_reasons]
      end
    end

    # FORENAME SURNAME
    def created_by_lastname
      created_by_name.to_s.split.last
    end

    def override_reasons
      reasons = super
      return unless reasons.is_a?(Array)

      reasons.filter_map { it.try(:humanize).presence }.join(', ').presence
    end
  end
end
