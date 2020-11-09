# frozen_string_literal: true

class Prison
  attr_reader :code

  class << self
    def active
      PrisonEmumerator.new Allocation.distinct.pluck(:prison)
    end
  end

  def initialize(prison_code)
    @code = prison_code
  end

  def name
    PrisonService.name_for(@code)
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

  class PrisonEmumerator
    include Enumerable

    def initialize codes
      @codes = codes
    end

    def each
      @codes.each { |code| yield Prison.new(code) }
    end
  end

  class OffenderEnumerator
    include Enumerable
    FETCH_SIZE = 200 # How many records to fetch from nomis at a time

    def initialize(prison)
      @prison = prison
    end

    def each
      first_page = HmppsApi::PrisonApi::OffenderApi.list(
        @prison,
        0,
        page_size: FETCH_SIZE
      )
      offenders = first_page.data
      enrich_offenders(offenders)
      offenders.each { |offender| yield offender }

      1.upto(first_page.total_pages - 1).each do |page_number|
        offenders = HmppsApi::PrisonApi::OffenderApi.list(
          @prison,
          page_number,
          page_size: FETCH_SIZE
        ).data

        enrich_offenders(offenders)

        offenders.each { |offender| yield offender }
      end
    end

  private

    def enrich_offenders(offenders)
      booking_ids = offenders.map(&:booking_id)
      sentence_details = HmppsApi::PrisonApi::OffenderApi.get_bulk_sentence_details(booking_ids)

      nomis_ids = offenders.map(&:offender_no)
      mapped_tiers = CaseInformationService.get_case_information(nomis_ids)

      temp_movements = HmppsApi::PrisonApi::MovementApi.latest_temp_movement_for(nomis_ids)

      offenders.each { |offender|
        sentencing = sentence_details[offender.booking_id]
        offender.sentence = sentencing if sentencing.present?

        case_info_record = mapped_tiers[offender.offender_no]
        offender.load_case_information(case_info_record)

        offender.latest_movement = temp_movements[offender.offender_no]
      }
      HmppsApi::PrisonApi::OffenderApi.add_arrival_dates(offenders)
    end
  end
end
