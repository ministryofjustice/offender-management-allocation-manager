require 'rails_helper'

RSpec.describe OpenPrisonTransferJob, type: :job do
  include ActiveJob::TestHelper

  let(:nomis_offender_id) { 'G3462VT' }
  let(:nomis_staff_id) { 485_637 }
  let(:open_prison_code) { 'HDI' }
  let(:movement_json) {
    {
      offenderNo: nomis_offender_id,
      fromAgency: "LEI",
      toAgency: open_prison_code,
      movementType: "TRN",
      directionCode: "IN"
    }.to_json
  }
  let(:elite2api) { 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api' }

  before do
    stub_auth_token
  end

  it 'does not send an email when no LDU email address' do
    allow(OffenderService).to receive(:get_offender).and_return(Nomis::Offender.new.tap{ |o|
      o.prison_id = open_prison_code
      o.offender_no =  nomis_offender_id
      o.case_allocation = 'NPS'
    })

    stub_request(:get, "#{elite2api}/staff/#{nomis_staff_id}/emails").
      to_return(status: 200, body: ['pom@localhost.local'].to_json, headers: {})

    described_class.perform_now(movement_json)

    email_job = enqueued_jobs.first
    expect(email_job).to be_nil
  end

  it 'sends an email when there was no previous allocation' do
    allow(OffenderService).to receive(:get_offender).and_return(Nomis::Offender.new.tap{ |o|
      o.prison_id = open_prison_code
      o.offender_no =  nomis_offender_id
      o.case_allocation = 'NPS'
      o.ldu = LocalDivisionalUnit.new.tap { |l| l.email_address = 'ldu@local.local' }
      o.first_name = 'First'
      o.last_name = 'Last'
    })

    stub_request(:get, "#{elite2api}/staff/#{nomis_staff_id}/emails").
      to_return(status: 200, body: ['pom@localhost.local'].to_json, headers: {})

    expect {
      described_class.perform_now(movement_json)
    }.to have_enqueued_job.with { |_job, _method, _deliver_when, args|
      expect(args[:prisoner_number]).to eq(nomis_offender_id)
      expect(args[:prisoner_name]).to eq('Last, First')
      expect(args[:responsible_pom_name]).to eq('N/A')
      expect(args[:responsible_pom_email]).to eq('N/A')
      expect(args[:prison_name]).to eq('HMP/YOI Hatfield')
      expect(args[:previous_prison_name]).to eq('HMP Leeds')
    }
  end

  it 'can use previous allocation details where they exist', versioning: true do
    allow(OffenderService).to receive(:get_offender).and_return(Nomis::Offender.new.tap{ |o|
      o.prison_id = open_prison_code
      o.offender_no =  nomis_offender_id
      o.case_allocation = 'NPS'
      o.ldu = LocalDivisionalUnit.new.tap { |l| l.email_address = 'ldu@local.local' }
      o.first_name = 'First'
      o.last_name = 'Last'
    })

    stub_request(:get, "#{elite2api}/staff/#{nomis_staff_id}/emails").
      to_return(status: 200, body: ['pom@localhost.local'].to_json, headers: {})

    # Create an allocation where the offender is allocated, and then deallocate so we can
    # test finding the last pom that was allocated to this offender ....
    create(:allocation_version, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: nomis_staff_id, prison: 'LEI', primary_pom_name: 'Primary POMName')
    AllocationVersion.deallocate_offender(nomis_offender_id, AllocationVersion::OFFENDER_TRANSFERRED)

    expect {
      described_class.perform_now(movement_json)
    }.to have_enqueued_job.with { |_job, _method, _deliver_when, args|
      expect(args[:prisoner_number]).to eq(nomis_offender_id)
      expect(args[:prisoner_name]).to eq('Last, First')
      expect(args[:responsible_pom_name]).to eq('Primary POMName')
      expect(args[:responsible_pom_email]).to eq('pom@localhost.local')
      expect(args[:prison_name]).to eq('HMP/YOI Hatfield')
      expect(args[:previous_prison_name]).to eq('HMP Leeds')
      expect(args[:email]).to eq('ldu@local.local')
    }
  end
end
