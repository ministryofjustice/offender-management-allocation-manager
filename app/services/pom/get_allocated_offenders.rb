# frozen_string_literal: true

require_relative '../application_service'

module POM
  class GetAllocatedOffenders < ApplicationService
    attr_reader :prison, :staff_id

    def initialize(staff_id, prison)
      @staff_id = staff_id
      @prison = prison
    end

    # rubocop:disable Metrics/MethodLength
    def call
      allocation_list = AllocationVersion.active_pom_allocations(
        @staff_id,
        @prison
      )

      offender_ids = allocation_list.map(&:nomis_offender_id)
      booking_ids = allocation_list.map(&:nomis_booking_id)

      # Get an offender map of offender_id to sentence details and a hash of
      # offender_no to case_info_details so we can fill in a fake offender
      # object for each allocation. This will allow us to calculate the
      # pom responsibility without having to make an API request per-offender.
      offender_map = OffenderService::SentenceDetails.call(booking_ids)
      case_info = CaseInformationService.get_case_info_for_offenders(offender_ids)

      allocation_list.map do |alloc|
        offender_stub = Nomis::Models::Offender.new
        offender_stub.sentence = offender_map[alloc.nomis_booking_id]

        record = case_info[alloc.nomis_offender_id]
        if record.present?
          offender_stub.tier = record.tier
          offender_stub.case_allocation = record.case_allocation
          offender_stub.omicable = record.omicable
        end

        if alloc.for_primary_only?
          responsibility =
            ResponsibilityService.new.calculate_pom_responsibility(offender_stub)
        else
          responsibility = ResponsibilityService::COWORKING
        end

        AllocationWithSentence.new(
          @staff_id,
          alloc,
          offender_map[alloc.nomis_booking_id],
          responsibility
        )
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
