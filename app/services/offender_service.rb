# frozen_string_literal: true

class OffenderService
  def self.get_offender(offender_no)
    Nomis::Elite2::OffenderApi.get_offender(offender_no).tap { |o|
      next false if o.nil?

      record = CaseInformation.find_by(nomis_offender_id: offender_no)

      if record.present?
        o.tier = record.tier
        o.case_allocation = record.case_allocation
        o.omicable = record.omicable == 'Yes'
        o.crn = record.crn
        o.mappa_level = record.mappa_level
      end

      sentence_detail = get_sentence_details([o.latest_booking_id])
      if sentence_detail.present? && sentence_detail.key?(o.latest_booking_id)
        o.sentence = sentence_detail[o.latest_booking_id]
      end

      o.category_code = Nomis::Elite2::OffenderApi.get_category_code(o.offender_no)
      o.main_offence = Nomis::Elite2::OffenderApi.get_offence(o.latest_booking_id)
    }
  end

  class OffenderEnumerator
    include Enumerable
    FETCH_SIZE = 200 # How many records to fetch from nomis at a time

    def initialize(prison)
      @prison = prison
    end

    def each
      number_of_requests = max_requests_count

      (0..number_of_requests).each do |request_no|
        offenders = get_offenders_for_prison(
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
      (info_request.meta.total_pages / FETCH_SIZE) + 1
    end

    # rubocop:disable Metrics/MethodLength
    def get_offenders_for_prison(page_number:, page_size:)
      offenders = Nomis::Elite2::OffenderApi.list(
        @prison,
        page_number,
        page_size: page_size
      ).data

      booking_ids = offenders.map(&:booking_id)
      sentence_details = Nomis::Elite2::OffenderApi.get_bulk_sentence_details(booking_ids)

      nomis_ids = offenders.map(&:offender_no)
      mapped_tiers = CaseInformationService.get_case_information(nomis_ids)

      offenders.select { |offender|
        sentencing = sentence_details[offender.booking_id]
        # TODO: - if sentencing.present? is false, then we crash in offender#sentenced?
        offender.sentence = sentencing if sentencing.present?

        record = mapped_tiers[offender.offender_no]
        if record
          offender.tier = record.tier
          offender.case_allocation = record.case_allocation
          offender.omicable = record.omicable == 'Yes'
          offender.crn = record.crn
          offender.mappa_level = record.mappa_level
        end

        true
      }
    end
    # rubocop:enable Metrics/MethodLength
  end

  def self.get_offenders_for_prison(prison)
    OffenderEnumerator.new(prison).select { |offender|
      offender.age >= 18 &&
      offender.sentenced? &&
      SentenceType.criminal?(offender.imprisonment_status)
    }
  end

  def self.get_unfiltered_offenders_for_prison(prison)
    # Returns all offenders at the provided prison, and does not
    # filter out under 18s or non-sentenced offenders in the same way
    # that get_offenders_for_prison does.
    OffenderEnumerator.new(prison)
  end

  def self.get_sentence_details(booking_ids)
    Nomis::Elite2::OffenderApi.get_bulk_sentence_details(booking_ids)
  end

  # Takes a list of OffenderSummary or Offender objects, and returns them with their
  # allocated POM name set in :allocated_pom_name.
  # This is now only used by the SearchController.
  # rubocop:disable Metrics/LineLength
  def self.set_allocated_pom_name(offenders, caseload)
    pom_names = PrisonOffenderManagerService.get_pom_names(caseload)
    nomis_offender_ids = offenders.map(&:offender_no)
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
  end
  # rubocop:enable Metrics/LineLength
end
