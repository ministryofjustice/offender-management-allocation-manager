# frozen_string_literal: true

class OffenderService
  def self.get_offender(offender_no)
    Nomis::Elite2::OffenderApi.get_offender(offender_no).tap { |o|
      next false if o.nil?

      record = CaseInformation.find_by(nomis_offender_id: offender_no)
      o.load_case_information(record)

      sentence_detail = get_sentence_details([o.booking_id])
      if sentence_detail.present? && sentence_detail.key?(o.booking_id)
        o.sentence = sentence_detail[o.booking_id]
      end

      o.category_code = Nomis::Elite2::OffenderApi.get_category_code(o.offender_no)
      o.main_offence = Nomis::Elite2::OffenderApi.get_offence(o.booking_id)
    }
  end

  def self.get_multiple_offenders(offender_ids)
    offenders = Nomis::Elite2::OffenderApi.get_multiple_offenders(offender_ids)

    booking_ids = offenders.map(&:booking_id)
    sentence_details = Nomis::Elite2::OffenderApi.get_bulk_sentence_details(booking_ids)

    nomis_ids = offenders.map(&:offender_no)
    mapped_tiers = CaseInformationService.get_case_information(nomis_ids)

    offenders.each { |offender|
      sentencing = sentence_details[offender.booking_id]
      offender.sentence = sentencing if sentencing.present?

      case_info_record = mapped_tiers[offender.offender_no]
      offender.load_case_information(case_info_record)
    }
  end

  def self.get_sentence_details(booking_ids)
    Nomis::Elite2::OffenderApi.get_bulk_sentence_details(booking_ids)
  end

  # Takes a list of OffenderSummary or Offender objects, and returns them with their
  # allocated POM name set in :allocated_pom_name.
  # This is now only used by the SearchController.
  def self.set_allocated_pom_name(offenders, prison_id)
    pom_names = PrisonOffenderManagerService.get_pom_names(prison_id)
    nomis_offender_ids = offenders.map(&:offender_no)
    offender_to_staff_hash = Allocation.
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

    offenders.each do |offender|
      if offender_to_staff_hash.key?(offender.offender_no)
        offender.allocated_pom_name = offender_to_staff_hash[offender.offender_no][:pom_name]
        offender.allocation_date = offender_to_staff_hash[offender.offender_no][:allocation_date]
      end
    end
    offenders
  end
end
