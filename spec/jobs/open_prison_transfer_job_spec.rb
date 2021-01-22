require 'rails_helper'

RSpec.describe OpenPrisonTransferJob, type: :job do
  include ActiveJob::TestHelper

  let(:nomis_offender_id) { 'G3462VT' }
  let(:nomis_staff_id) { 485_637 }
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
    stub_pom poms.first
  end

  it 'does not send an email if offender_no not found on Nomis' do
    allow(OffenderService).to receive(:get_offender).and_return(nil)

    described_class.perform_now(movement_json)
    email_job = enqueued_jobs.first
    expect(email_job).to be_nil
  end

  it 'does not send an email if the offender case_information is not NPS' do
    allow(OffenderService).to receive(:get_offender).
      and_return(HmppsApi::Offender.new(offender_no: nomis_offender_id,
                                     prison_id: open_prison_code).tap { |o|
                   o.load_case_information(build(:case_information, case_allocation: 'CRC'))
                 })
    described_class.perform_now(movement_json)

    email_job = enqueued_jobs.first
    expect(email_job).to be_nil
  end

  it 'does not send an email when no LDU email address' do
    allow(OffenderService).to receive(:get_offender).
      and_return(HmppsApi::Offender.new(offender_no: nomis_offender_id,
                                     prison_id: open_prison_code
      ).tap { |o|
                   o.load_case_information(build(:case_information,
                                                 case_allocation: 'NPS',
                                                 team: build(:team, local_divisional_unit: build(:local_divisional_unit, email_address: nil))))
                 })

    described_class.perform_now(movement_json)

    email_job = enqueued_jobs.first
    expect(email_job).to be_nil
  end

  it 'sends an email when there was no previous allocation' do
    allow(OffenderService).to receive(:get_offender).
      and_return(HmppsApi::Offender.new(offender_no: nomis_offender_id,
                                     prison_id: open_prison_code,
                                     first_name: 'First',
                                     last_name: 'Last').tap { |o|
                   o.load_case_information(build(:case_information,
                                                 case_allocation: 'NPS',
                                                 team: build(:team,
                                                             local_divisional_unit: LocalDivisionalUnit.new.tap { |l| l.email_address = 'ldu@local.local' })))
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

  it 'can use previous allocation details where they exist' do
    offender = build(:nomis_offender, first_name: 'First', last_name: 'Last')
    stub_offenders_for_prison(closed_prison_code, [offender])
    allow(OffenderService).to receive(:get_offender).
      and_return(HmppsApi::Offender.new(offender_no: nomis_offender_id,
                                     prison_id: open_prison_code,
                                     first_name: 'First',
                                     last_name: 'Last'
      ).tap { |o|
                   o.load_case_information(build(:case_information,
                                                 case_allocation: 'NPS',
                                                 team: build(:team,
                                                             local_divisional_unit:  LocalDivisionalUnit.new.tap { |l| l.email_address = 'ldu@local.local' })))
                 })

    # Create an allocation where the offender is allocated, and then deallocate so we can
    # test finding the last pom that was allocated to this offender ....
    alloc = create(:allocation, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: other_staff_id, prison: closed_prison_code,
                                primary_pom_name: 'Primary POMName')
    alloc.update(primary_pom_nomis_id: nomis_staff_id)
    alloc.offender_transferred

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

  context "when a Welsh offender is transferred to Prescoed open prison" do
    let(:prescoed) { 'UPI' }

    let(:movement_json) do
      {
        offender_no: nomis_offender_id,
        from_agency: closed_prison_code,
        to_agency: prescoed,
        movement_type: "TRN",
        direction_code: "IN"
      }.to_json
    end

    context 'with an indeterminate offender' do
      it 'sends an email to the LDU' do
        offender = build(:nomis_offender, imprisonmentStatus: 'LIFE', first_name: 'First', last_name: 'Last', sentence_type: :indeterminate)
        stub_offenders_for_prison(closed_prison_code, [offender])

        allow(OffenderService).to receive(:get_offender).
        and_return(HmppsApi::Offender.new(offender_no: nomis_offender_id,
                                          prison_id: prescoed,
                                          first_name: 'First',
                                          last_name: 'Last',
                                          sentence_type: SentenceType.new("LIFE")
        ).tap { |o|
          o.load_case_information(build(:case_information, :welsh, crn: 'A123j787DD',
                                        case_allocation: 'NPS',
                                        team: build(:team,
                                                    local_divisional_unit: build(:local_divisional_unit, name: 'ldu12', email_address: 'ldu@ldu12.gov.uk'))))
        })

        alloc = create(:allocation, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: other_staff_id,
               prison: closed_prison_code, primary_pom_name: 'Primary POMName')

        alloc.update(primary_pom_nomis_id: nomis_staff_id)
        alloc.offender_transferred

        fakejob = double
        allow(fakejob).to receive(:deliver_later)

        # this correctly skips the 'send email' method and goes to 'prescoed send mail' but this method hasn't been created yet
        expect(CommunityMailer).to receive(:omic_open_prison_community_allocation).with(hash_including(
                                                                                          nomis_offender_id: nomis_offender_id,
                                                                                          prisoner_name: 'Last, First',
                                                                                          crn: 'A123j787DD',
                                                                                          ldu_email: 'ldu@ldu12.gov.uk',
                                                                                          prison: 'HMP/YOI Prescoed',
                                                                                          pom_name: 'Primary POMName',
                                                                                          pom_email: 'pom@localhost.local'
                                                                                        )).and_return(fakejob)

        expect { described_class.perform_now(movement_json) }.to change(EmailHistory, :count).by(1)
      end
    end

    context "with a determinate offender" do
      it 'does not send an email to the LDU' do
        offender = build(:nomis_offender, imprisonmentStatus: 'SENT03', first_name: 'First', last_name: 'Last', sentence_type: :determinate)
        stub_offenders_for_prison(closed_prison_code, [offender])

        allow(OffenderService).to receive(:get_offender).
        and_return(HmppsApi::Offender.new(offender_no: nomis_offender_id,
                                          prison_id: prescoed,
                                          first_name: 'First',
                                          last_name: 'Last',
                                          sentence_type: SentenceType.new("SENT03")
        ).tap { |o|
          o.load_case_information(build(:case_information, :welsh,
                                        case_allocation: 'NPS',
                                        team: build(:team,
                                                    local_divisional_unit:  LocalDivisionalUnit.new.tap { |l| l.email_address = 'ldu@local.local' })))
        })

        alloc = create(:allocation, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: other_staff_id,
                       prison: closed_prison_code, primary_pom_name: 'Primary POMName')

        alloc.update(primary_pom_nomis_id: nomis_staff_id)
        alloc.offender_transferred

        expect { described_class.perform_now(movement_json) }.to change(EmailHistory, :count).by(0)
        expect_any_instance_of(PomMailer).not_to receive(:responsibility_override_open_prison)
        expect_any_instance_of(CommunityMailer).not_to receive(:omic_open_prison_community_allocation)
      end
    end
  end
end
