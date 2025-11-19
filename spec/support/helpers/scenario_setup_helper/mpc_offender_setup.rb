module ScenarioSetupHelper
  module MpcOffenderSetup
    def new_mpc_offender(nomis_offender_id, prison_code: 'LEI')
      MpcOffender
        .new(offender: create(:offender, nomis_offender_id:),
             prison: create(:prison, code: prison_code),
             prison_record: build(:hmpps_api_offender, prisonerNumber: nomis_offender_id))
        .tap { create(:case_information, nomis_offender_id:, manual_entry: false) }
    end
  end
end
