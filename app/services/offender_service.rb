class OffenderService
  # rubocop:disable Metrics/MethodLength
  def self.get_offender(offender_no)
    Nomis::Api::OffenderApi.get(offender_no).tap { |o|
      record = CaseInformation.where(nomis_offender_id: offender_no)

      unless record.empty?
        o.tier = record.first.tier
        o.case_allocation = record.first.case_allocation
      end

      sentence_detail = get_sentence_details([offender_no])
      o.release_date = sentence_detail[offender_no].release_date
      o.sentence_date = sentence_detail[offender_no].sentence_date

      o.main_offence = Nomis::Api::OffenderApi.get_offence(o.latest_booking_id)
    }
  end

  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/LineLength
  def self.get_offenders_for_prison(prison, page_number: 0, page_size: 10)
    offenders = Nomis::Api::OffenderApi.list(
      prison,
      page_number,
      page_size: page_size
    ).data

    offender_ids = offenders.map(&:offender_no)

    cases = CaseInformation.where(nomis_offender_id: offender_ids)
    tier_map = cases.each_with_object({}) do |c, hash|
      hash[c.nomis_offender_id] = c
    end

    sentence_details = if offender_ids.count > 0
                         sentence_details = Nomis::Api::OffenderApi.get_bulk_sentence_details(
                           offender_ids
                         )
                       else
                         {}
                       end

    offenders.select { |offender|
      offender.release_date = sentence_details[offender.offender_no].release_date
      if offender.release_date.present?
        record = tier_map[offender.offender_no]
        offender.tier = record.tier if record
        offender.case_allocation = record.case_allocation if record
        offender.sentence_date = sentence_details[offender.offender_no].sentence_date
        true
      else
        false
      end
    }
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/LineLength

  def self.get_sentence_details(offender_id_list)
    Nomis::Api::OffenderApi.get_bulk_sentence_details(offender_id_list)
  end

  def self.allocations_for_offenders(offender_id_list)
    Allocation.where(
      nomis_offender_id: offender_id_list, active: true
    ).preload(:pom_detail)
  end

  # Takes a list of OffenderShort objects, and returns them with their
  # allocated POM name set in :allocated_pom_name
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/LineLength
  def self.set_allocated_pom_name(offenders, caseload)
    pom_names = PrisonOffenderManagerService.get_pom_names(caseload)
    offender_ids = offenders.map(&:offender_no)
    offender_to_staff_hash = allocations_for_offenders(offender_ids).map { |a|
      [
        a.nomis_offender_id,
        {
          pom_name: pom_names[a.pom_detail.nomis_staff_id],
          allocation_date: a.created_at
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
  # rubocop:enable Metrics/MethodLength
end
