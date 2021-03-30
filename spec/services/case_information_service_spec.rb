require 'rails_helper'

describe CaseInformationService do
  let(:caseinfo) {
    create(:case_information,
           nomis_offender_id: 'X1000XX',
           tier: 'A',
           case_allocation: 'NPS',
           probation_service: 'Wales'
    )
  }

  it "can get case information" do
    cases = described_class.get_case_information([caseinfo.nomis_offender_id])
    expect(cases).to be_kind_of(Hash)
    expect(cases.length).to eq(1)
    expect(cases[caseinfo.nomis_offender_id]).to be_kind_of(CaseInformation)
  end

  it 'can eager load the responsibility association' do
    create(:responsibility, nomis_offender_id: caseinfo.nomis_offender_id)
    cases = described_class.get_case_information([caseinfo.nomis_offender_id])

    expect(cases[caseinfo.nomis_offender_id].association(:responsibility).loaded?).to eq(true)
  end

  it "can delete case information" do
    cases = described_class.get_case_information([caseinfo.nomis_offender_id])
    expect(cases.length).to eq(1)

    CaseInformation.where(nomis_offender_id: ['X1000XX']).destroy_all

    cases = described_class.get_case_information(['X1000XX'])
    expect(cases.length).to eq(0)
  end
end
