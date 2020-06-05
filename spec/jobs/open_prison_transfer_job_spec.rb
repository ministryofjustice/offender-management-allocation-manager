require 'rails_helper'

RSpec.describe OpenPrisonTransferJob, type: :job do
  include ActiveJob::TestHelper

  let(:nomis_offender_id) { 'G3462VT' }
  let(:nomis_staff_id) { 485_735 }
  let(:other_staff_id) { 485_636 }
  let(:open_prison_code) { 'HDI' }
  let(:closed_prison_code) { 'LEI' }
  let(:poms) {
    [build(:pom,
           staffId: nomis_staff_id,
           firstName: 'Firstname',
           lastName: 'Lastname',
           position: RecommendationService::PRISON_POM,
           emails: ['pom@localhost.local']
     )]
  }
  let(:movement_json) {
    {
      offender_no: nomis_offender_id,
      from_agency: closed_prison_code,
      to_agency: open_prison_code,
      movement_type: "TRN",
      direction_code: "IN"
    }.to_json
  }

  before do
    stub_auth_token
    stub_poms(closed_prison_code, poms)
  end

  it 'does not send an email if offender_no not found on Nomis' do
    allow(OffenderService).to receive(:get_offender).and_return(nil)

    described_class.perform_now(movement_json)
    email_job = enqueued_jobs.first
    expect(email_job).to be_nil
  end

  it 'does not send an email if the offender case_information is not NPS' do
    allow(OffenderService).to receive(:get_offender).and_return(Nomis::Offender.new.tap { |o|
      o.prison_id = open_prison_code
      o.offender_no =  nomis_offender_id
      o.case_allocation = 'CRC'
    })
    described_class.perform_now(movement_json)

    email_job = enqueued_jobs.first
    expect(email_job).to be_nil
  end

  it 'does not send an email when no LDU email address' do
    allow(OffenderService).to receive(:get_offender).and_return(Nomis::Offender.new.tap { |o|
      o.prison_id = open_prison_code
      o.offender_no =  nomis_offender_id
      o.case_allocation = 'NPS'
    })

    described_class.perform_now(movement_json)

    email_job = enqueued_jobs.first
    expect(email_job).to be_nil
  end

  it 'sends an email when there was no previous allocation' do
    allow(OffenderService).to receive(:get_offender).and_return(Nomis::Offender.new.tap { |o|
      o.prison_id = open_prison_code
      o.offender_no =  nomis_offender_id
      o.case_allocation = 'NPS'
      o.ldu = LocalDivisionalUnit.new.tap { |l| l.email_address = 'ldu@local.local' }
      o.first_name = 'First'
      o.last_name = 'Last'
    })

    fakejob = double
    allow(fakejob).to receive(:deliver_later)

    expect(PomMailer).to receive(:responsibility_override_open_prison).with(hash_including(
                                                                              prisoner_number: nomis_offender_id,
                                                                              prisoner_name: 'Last, First',
                                                                              responsible_pom_name: 'N/A',
                                                                              responsible_pom_email: 'N/A',
                                                                              prison_name: 'HMP/YOI Hatfield',
                                                                              previous_prison_name: 'HMP Leeds'
    )).and_return(fakejob)

    described_class.perform_now(movement_json)
  end

  it 'can use previous allocation details where they exist', versioning: true do
    allow(OffenderService).to receive(:get_offender).and_return(Nomis::Offender.new.tap { |o|
      o.prison_id = open_prison_code
      o.offender_no =  nomis_offender_id
      o.case_allocation = 'NPS'
      o.ldu = LocalDivisionalUnit.new.tap { |l| l.email_address = 'ldu@local.local' }
      o.first_name = 'First'
      o.last_name = 'Last'
    })

    # Create an allocation where the offender is allocated, and then deallocate so we can
    # test finding the last pom that was allocated to this offender ....
    alloc = create(:allocation, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: other_staff_id, prison: 'LEI',
                                primary_pom_name: 'Primary POMName')
    alloc.update(primary_pom_nomis_id: nomis_staff_id)
    alloc.deallocate_offender(Allocation::OFFENDER_TRANSFERRED)

    fakejob = double
    allow(fakejob).to receive(:deliver_later)

    expect(PomMailer).to receive(:responsibility_override_open_prison).with(hash_including(
                                                                              prisoner_number: nomis_offender_id,
                                                                              prisoner_name: 'Last, First',
                                                                              responsible_pom_name: 'Primary POMName',
                                                                              responsible_pom_email: 'pom@localhost.local',
                                                                              prison_name: 'HMP/YOI Hatfield',
                                                                              previous_prison_name: 'HMP Leeds'
    )).and_return(fakejob)

    described_class.perform_now(movement_json)
  end
end
