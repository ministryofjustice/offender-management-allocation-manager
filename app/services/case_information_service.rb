# frozen_string_literal: true

class CaseInformationService
  def self.get_case_info_for_offenders(nomis_id_list)
    CaseInformation.where(
      nomis_offender_id: nomis_id_list
    ).each_with_object({}) { |caseinfo, hash|
      hash[caseinfo.nomis_offender_id] = caseinfo
    }
  end

  def self.get_case_information(offender_ids)
    CaseInformation.where(nomis_offender_id: offender_ids).map { |case_info|
      [case_info.nomis_offender_id, case_info]
    }.to_h
  end

  def self.delete_information(nomis_offender_id)
    CaseInformation.where(nomis_offender_id: nomis_offender_id).destroy_all
  end
end
