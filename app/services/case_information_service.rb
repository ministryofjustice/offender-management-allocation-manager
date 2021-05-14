# frozen_string_literal: true

class CaseInformationService
  def self.get_case_information(offender_ids)
    CaseInformation.includes(:responsibility, :early_allocations, :local_delivery_unit).
      where(nomis_offender_id: offender_ids).index_by(&:nomis_offender_id)
  end
end
