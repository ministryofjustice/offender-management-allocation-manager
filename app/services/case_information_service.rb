class CaseInformationService
  def self.get_case_information(prison)
    cases = CaseInformation.where(prison: prison)
    cases.each_with_object({}) do |c, hash|
      hash[c.nomis_offender_id] = c
    end
  end
end
