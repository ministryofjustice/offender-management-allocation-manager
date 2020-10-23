require 'rails_helper'

RSpec.describe HandoverFollowUpJob, type: :job do
  include ActiveJob::TestHelper

  let(:pom) do
    OpenStruct.new  staff_id: 99999,
                    first_name: "MARY",
                    last_name: "JAMES",
                    agency_id: "LEI",
                    full_name: "JAMES, MARY",
                    email_address: "mary.james@someprison.gov.uk"
  end

  let(:indeterminate_without_ted) do
    build_offender(sentence_type: :indeterminate, release_date: nil, ted: nil)
  end

  let(:determinate_offender) do
    build_offender(sentence_type: :determinate, release_date: Time.zone.today + 8.months, ted: nil)
  end

  it "does not queue jobs for LDU's without email addresses" do
    case_info = create(:case_information, nomis_offender_id: determinate_offender.offender_no,
                       team: build(:team, local_divisional_unit: build(:local_divisional_unit, email_address: nil)))

    create(:allocation, nomis_offender_id: determinate_offender.offender_no)

    allow(OffenderService).to receive(:get_offender).and_return(determinate_offender)
    determinate_offender.load_case_information(case_info)

    expect(case_info.team.local_divisional_unit.email_address.present?).to be false
    expect { described_class.perform_now(Time.zone.today) }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
  end

  it "does not queue jobs for offender's who have COM's assigned" do
    case_info = create(:case_information, nomis_offender_id: determinate_offender.offender_no)
    create(:allocation, nomis_offender_id: determinate_offender.offender_no, com_name: "Betty White")

    allow(OffenderService).to receive(:get_offender).and_return(determinate_offender)
    determinate_offender.load_case_information(case_info)

    expect { described_class.perform_now(Time.zone.today) }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
  end

  it 'does not queue jobs for offender whose handover dates do not match date specified' do
    case_info = create(:case_information, nomis_offender_id: determinate_offender.offender_no,
                       team: build(:team, local_divisional_unit: build(:local_divisional_unit)))

    create(:allocation, nomis_offender_id: determinate_offender.offender_no)

    allow(OffenderService).to receive(:get_offender).and_return(determinate_offender)
    determinate_offender.load_case_information(case_info)

    expect { described_class.perform_now(Time.zone.today) }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
  end

  it "does not queue jobs for offender's who do not have handover_start_dates" do
    case_info = create(:case_information, nomis_offender_id: indeterminate_without_ted.offender_no,
                       team: build(:team, local_divisional_unit: build(:local_divisional_unit)))

    create(:allocation, nomis_offender_id: indeterminate_without_ted.offender_no)

    allow(OffenderService).to receive(:get_offender).and_return(indeterminate_without_ted)
    indeterminate_without_ted.load_case_information(case_info)

    expect { described_class.perform_now(Time.zone.today) }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
  end

  it 'queues a job when offenders handover date matches date specified' do
    allow(PrisonOffenderManagerService).to receive(:get_pom_at).and_return(pom)

    case_info = create(:case_information, nomis_offender_id: determinate_offender.offender_no,
                         team: build(:team, local_divisional_unit: build(:local_divisional_unit)))

    create(:allocation, nomis_offender_id: determinate_offender.offender_no,
           primary_pom_nomis_id: pom.staff_id,
           primary_pom_name: pom.full_name)

    allow(OffenderService).to receive(:get_offender).and_return(determinate_offender)

    determinate_offender.load_case_information(case_info)
    date_of_handover = determinate_offender.handover_start_date

    expect { described_class.perform_now(date_of_handover) }
      .to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with("PomMailer", "handover_chase_email", "deliver_now",
                args: [{ nomis_offender_id: determinate_offender.offender_no,
                          offender_name: determinate_offender.full_name,
                          offender_crn: determinate_offender.crn,
                          ldu_email: determinate_offender.ldu.email_address,
                          prison: "HMP Leeds",
                          start_date: determinate_offender.handover_start_date,
                          responsibility_handover_date: determinate_offender.responsibility_handover_date,
                          pom_name: pom.full_name,
                          pom_email: pom.email_address }]
          )
  end

  def build_offender(sentence_type:, release_date:, ted:)
    build(:offender, sentence_type, latestLocationId: 'LEI',
          sentence: build(:sentence_detail,
                          sentenceStartDate: Time.zone.today - 11.months,
                          conditionalReleaseDate: release_date,
                          automaticReleaseDate: release_date,
                          releaseDate: nil,
                          tariffDate: ted))
  end
end
