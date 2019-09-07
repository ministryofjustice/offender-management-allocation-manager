module OffenderService
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
        next false if offender.age < 18
        next false if SentenceType.civil?(offender.imprisonment_status)

        sentencing = sentence_details[offender.booking_id]
        # TODO: - if sentencing.present? is false, then we crash in offender#sentenced?
        offender.sentence = sentencing if sentencing.present?
        next false unless offender.sentenced?

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
end
