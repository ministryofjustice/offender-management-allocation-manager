require 'rails_helper'

RSpec.describe MovementsOnDateJob, type: :job do
  let(:nomis_offender_id) { 'G3462VT' }
  let!(:alloc) { create(:allocation, nomis_offender_id: nomis_offender_id, secondary_pom_nomis_id: 123_435, prison: 'MDI') }

  before do
    stub_auth_token
  end

  it 'deallocates' do
    allow(OffenderService).to receive(:get_offender).and_return(build(:offender))

    stub_request(:get, "#{ApiHelper::T3}/movements?fromDateTime=2018-06-30T00:00&movementDate=2019-06-30").
      to_return(body: [
        { offenderNo: nomis_offender_id,
          fromAgency: "MDI",
          toAgency: "WEI",
          movementType: "ADM",
          directionCode: "IN"
        }].to_json)

    pom = build(:pom, staffId: 485926)
    stub_poms('MDI', [pom])
    stub_pom pom
    stub_offenders_for_prison('MDI', [])

    expect(alloc.primary_pom_nomis_id).not_to be_nil
    expect(alloc.secondary_pom_nomis_id).not_to be_nil

    described_class.perform_now(Date.new(2019, 7, 1).to_s)

    alloc.reload

    expect(alloc.primary_pom_nomis_id).to be_nil
    expect(alloc.secondary_pom_nomis_id).to be_nil
  end
end
