require 'rails_helper'

RSpec.describe MovementsOnDateJob, type: :job do
  let(:nomis_offender_id) { nomis_offender.fetch(:prisonerNumber) }
  let(:nomis_offender) { build(:nomis_offender, prisonId: to_prison_code) }
  let(:case_info) { create(:case_information) }
  let!(:offender_record) { create(:offender, nomis_offender_id: nomis_offender_id, case_information: case_info) }
  let(:today) { Time.zone.today }
  let(:yesterday) { today - 1.day }
  let(:pom) { build(:pom) }
  let!(:allocation) { create(:allocation_history, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: pom.staff_id, prison: from_prison_code) }
  let(:mail_params) {
    {
      email: pom.email_address,
      pom_name: pom.first_name.titleize,
      offender_name: "#{nomis_offender.fetch(:lastName)}, #{nomis_offender.fetch(:firstName)}".titleize,
      nomis_offender_id: nomis_offender_id,
      prison_name: Prison.find(from_prison_code).name,
      url: "http://localhost:3000/prisons/#{from_prison_code}/staff/#{pom.staff_id}/caseload"
    }
  }

  before do
    stub_offender(nomis_offender)
    stub_poms(from_prison_code, [pom])

    # Stub offender movements from yesterday
    stub_request(:get, "#{ApiHelper::T3}/movements?fromDateTime=#{yesterday - 1.year}T00:00&movementDate=#{yesterday}").
      to_return(body: [movement].to_json)

    # Expect POM to be emailed about the deallocation
    expect(PomMailer).to receive(:offender_deallocated).with(mail_params).and_return(double(deliver_later: nil))
  end

  context 'when the offender has been released from prison' do
    let(:from_prison_code) { create(:prison).code }
    let(:to_prison_code) { 'OUT' } # "OUT" is the prison code NOMIS uses to mean "not in prison"

    let(:movement) {
      attributes_for(:movement,
                     offenderNo: nomis_offender_id,
                     movementType: 'REL',
                     directionCode: 'OUT',
                     fromAgency: from_prison_code,
                     toAgency: to_prison_code)
    }

    it 'deallocates and emails the POM' do
      expect(allocation).to be_active
      described_class.perform_now(today.to_s)
      allocation.reload
      expect(allocation).not_to be_active
    end
  end

  context 'when the offender has transferred to a different prison' do
    let(:from_prison_code) { create(:prison).code }
    let(:to_prison_code) { create(:prison).code }

    let(:movement) {
      attributes_for(:movement,
                     offenderNo: nomis_offender_id,
                     movementType: 'ADM',
                     directionCode: 'IN',
                     fromAgency: from_prison_code,
                     toAgency: to_prison_code)
    }

    it 'deallocates and emails the POM' do
      expect(allocation).to be_active
      described_class.perform_now(today.to_s)
      allocation.reload
      expect(allocation).not_to be_active
    end
  end
end
