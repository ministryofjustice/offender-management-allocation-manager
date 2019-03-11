require 'rails_helper'

describe CaseInformationService, vcr: { cassette_name: :caseinfo_service_spec } do
  let (:caseinfo) {
    CaseInformation.find_or_create_by!(
      nomis_offender_id: 'X1000XX',
      tier: 'A',
      case_allocation: 'NPS',
      welsh_address: 'Yes',
      prison: 'LEI'
    )
  }

  it "can get case information" do
    cases = CaseInformationService.get_case_information(caseinfo.prison)
    expect(cases).to be_kind_of(Hash)
    expect(cases.length).to eq(1)
    expect(cases[caseinfo.nomis_offender_id]).to be_kind_of(CaseInformation)
  end

  it "can delete case information" do
    cases = CaseInformationService.get_case_information(caseinfo.prison)
    expect(cases.length).to eq(1)

    CaseInformationService.delete_information(caseinfo.nomis_offender_id)

    cases = CaseInformationService.get_case_information(caseinfo.prison)
    expect(cases.length).to eq(0)
  end

  it "can change prisons for case information" do
    cases = CaseInformationService.get_case_information(caseinfo.prison)
    expect(cases.length).to eq(1)

    CaseInformationService.change_prison(caseinfo.nomis_offender_id, 'LEI', 'SWI')

    cases = CaseInformationService.get_case_information('LEI')
    expect(cases.length).to eq(0)

    cases = CaseInformationService.get_case_information('SWI')
    expect(cases.length).to eq(1)
  end
end
