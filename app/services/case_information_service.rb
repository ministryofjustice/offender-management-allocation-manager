# frozen_string_literal: true

class CaseInformationService
  def self.get_case_info_for_offenders(nomis_id_list, prison)
    CaseInformation.where(
      nomis_offender_id: nomis_id_list, prison: prison
    ).each_with_object({}) { |caseinfo, hash|
      hash[caseinfo.nomis_offender_id] = caseinfo
    }
  end

  def self.get_case_information(prison)
    cases = CaseInformation.where(prison: prison)
    cases.each_with_object({}) do |c, hash|
      hash[c.nomis_offender_id] = c
    end
  end

  def self.change_prison(nomis_offender_id, old_prison, new_prison)
    CaseInformation.where(
      nomis_offender_id: nomis_offender_id, prison: old_prison
    ).update_all(prison: new_prison)
  end

  def self.delete_information(nomis_offender_id)
    CaseInformation.where(nomis_offender_id: nomis_offender_id).destroy_all
  end
end
