# frozen_string_literal: true

module Sar
  class AllocationHistory < BaseSarPresenter
    class << self
      def omitted_attributes
        [:primary_pom_name, :secondary_pom_name, :primary_pom_nomis_id, :secondary_pom_nomis_id]
      end

      def additional_methods
        [:primary_pom_last_name, :secondary_pom_last_name, :event, :event_trigger, :override_reasons]
      end
    end

    # SURNAME, FORENAME
    def primary_pom_last_name
      primary_pom_name.to_s.split(',').first
    end

    # SURNAME, FORENAME
    def secondary_pom_last_name
      secondary_pom_name.to_s.split(',').first
    end

    def event
      I18n.t(
        "sar.allocation_history.event.#{super}",
        default: super.try(:humanize)
      )
    end

    def event_trigger
      I18n.t(
        "sar.allocation_history.event_trigger.#{super}",
        default: super.try(:humanize)
      )
    end

    def override_reasons
      return if super.blank?

      reason = super.first

      I18n.t(
        "sar.allocation_history.override_reasons.#{reason}",
        default: reason.try(:humanize)
      )
    end
  end
end
