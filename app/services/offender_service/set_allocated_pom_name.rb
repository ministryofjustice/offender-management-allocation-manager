# frozen_string_literal: true

require_relative '../application_service'

module OffenderService
  class SetAllocatedPomName < ApplicationService
    attr_reader :offenders, :prison

    def initialize(offenders, prison)
      @offenders = offenders
      @prison = prison
    end

    # Takes a list of OffenderSummary or Offender objects, and returns them with their
    # allocated POM name set in :allocated_pom_name.
    # This is now only used by the SearchController.
    # rubocop:disable Metrics/LineLength
    def call
      pom_names = POMService::GetPomNames.call(@prison)
      nomis_offender_ids = @offenders.map(&:offender_no)

      offender_to_staff_hash = AllocationVersion.
        where(nomis_offender_id: nomis_offender_ids).
        map { |a|
          [
            a.nomis_offender_id,
            {
              pom_name: pom_names[a.primary_pom_nomis_id],
              allocation_date: (a.primary_pom_allocated_at || a.updated_at)&.to_date
            }
          ]
        }.to_h

      offenders.map do |offender|
        if offender_to_staff_hash.key?(offender.offender_no)
          offender.allocated_pom_name = offender_to_staff_hash[offender.offender_no][:pom_name]
          offender.allocation_date = offender_to_staff_hash[offender.offender_no][:allocation_date]
        end
        offender
      end
      # rubocop:enable Metrics/LineLength
    end
  end
end
