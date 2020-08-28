# frozen_string_literal: true

class Prison
  attr_reader :code

  def initialize(prison_code)
    @code = prison_code
  end

  def offenders
    OffenderEnumerator.new(@code).select do |offender|
      next if offender.age.blank?

      offender.age >= 18 &&
        (offender.sentenced? || offender.immigration_case?) &&
        offender.criminal_sentence?
    end
  end

  def unfiltered_offenders
    # Returns all offenders at the provided prison, and does not
    # filter out under 18s or non-sentenced offenders in the same way
    # that get_offenders_for_prison does.
    OffenderEnumerator.new(@code)
  end

  def allocations_for(staff_id)
    offender_hash = offenders.index_by(&:offender_no)
    allocations = Allocation.
      where(nomis_offender_id: offender_hash.keys).
      active_pom_allocations(staff_id, @code)
    allocations.map { |alloc|
      AllocatedOffender.new(staff_id, alloc, offender_hash.fetch(alloc.nomis_offender_id))
    }
  end

private

  class OffenderEnumerator
    include Enumerable
    FETCH_SIZE = 200 # How many records to fetch from nomis at a time

    def initialize(prison)
      @prison = prison
    end

    def each
      number_of_requests = max_requests_count

      (0..number_of_requests - 1).each do |request_no|
        offenders = fetch_page_of_offenders(
          page_number: request_no,
          page_size: FETCH_SIZE
        )

        offenders.each { |offender| yield offender }
      end
    end

  private

    def max_requests_count
      # Fetch the first 1 prisoners just for the total number of pages so that we
      # can send batched queries.
      info_request = Nomis::Elite2::OffenderApi.list(@prison, 1, page_size: 1)

      # The maximum number of pages we need to fetch before we have all of
      # the offenders
      (info_request.total_pages / FETCH_SIZE) + 1
    end

    def fetch_page_of_offenders(page_number:, page_size:)
      offenders = Nomis::Elite2::OffenderApi.list(
        @prison,
        page_number,
        page_size: page_size
      ).data

      booking_ids = offenders.map(&:booking_id)
      sentence_details = Nomis::Elite2::OffenderApi.get_bulk_sentence_details(booking_ids)

      nomis_ids = offenders.map(&:offender_no)
      mapped_tiers = CaseInformationService.get_case_information(nomis_ids)

      temp_movements = Nomis::Elite2::MovementApi.latest_temp_movement_for(nomis_ids)

      offenders.each { |offender|
        sentencing = sentence_details[offender.booking_id]
        offender.sentence = sentencing if sentencing.present?

        case_info_record = mapped_tiers[offender.offender_no]
        offender.load_case_information(case_info_record)

        offender.latest_movement = temp_movements[offender.offender_no]
      }
    end
  end
end
