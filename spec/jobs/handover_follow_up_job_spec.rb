require 'rails_helper'

RSpec.describe HandoverFollowUpJob, :allocation, type: :job do
  let(:determinate_offender) do
    build_offender(Time.zone.today + 8.months,
                   sentence_type: :determinate,
                   ard_crd_release: Time.zone.today + 8.months,
                   ted: nil)
  end

  let(:ldu) { create(:local_divisional_unit) }

  it 'does not send emails for offenders who are not in an active prison' do
    release_date = Time.zone.today + 8.months
    offender = build_offender(release_date,
                              'AGI',
                              sentence_type: :determinate,
                              ard_crd_release: release_date,
                              ted: nil)

    case_info = create(:case_information, nomis_offender_id: offender.offender_no,
                       team: build(:team, local_divisional_unit: ldu))

    create(:allocation, nomis_offender_id: offender.offender_no)

    allow(OffenderService).to receive(:get_offender).and_return(offender)
    offender.load_case_information(case_info)

    expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
    described_class.perform_now(ldu)
  end

  it 'does not send emails for un-sentenced offenders' do
    unsentenced_offender = build_offender(sentence_type: :determinate, ard_crd_release: nil, ted: nil)
    case_info = create(:case_information, nomis_offender_id: unsentenced_offender.offender_no,
                       team: build(:team, local_divisional_unit: ldu))

    create(:allocation, nomis_offender_id: unsentenced_offender.offender_no)

    allow(OffenderService).to receive(:get_offender).and_return(unsentenced_offender)
    unsentenced_offender.load_case_information(case_info)

    expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
    described_class.perform_now(ldu)
  end

  it 'does not send emails for offenders that do not exist' do
    offender = build_offender(sentence_type: :determinate, ard_crd_release: nil, ted: nil)
    create(:case_information, nomis_offender_id: offender.offender_no,
                       team: build(:team, local_divisional_unit: ldu))

    create(:allocation, nomis_offender_id: offender.offender_no)

    allow(OffenderService).to receive(:get_offender).and_return(nil)

    expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
    expect { described_class.perform_now(ldu) }.not_to raise_error
  end

  it 'does not send emails for offenders who have a COM assigned' do
    case_info = create(:case_information, nomis_offender_id: determinate_offender.offender_no, com_name: "Betty White")
    create(:allocation, nomis_offender_id: determinate_offender.offender_no)

    allow(OffenderService).to receive(:get_offender).and_return(determinate_offender)
    determinate_offender.load_case_information(case_info)

    expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
    described_class.perform_now(ldu)
  end

  it 'does not send emails for offenders who do not have a handover_start_date' do
    indeterminate_without_ted = build_offender(Time.zone.today + 10.months,
                                               sentence_type: :indeterminate,
                                               ard_crd_release: nil,
                                               ted: nil)

    case_info = create(:case_information, nomis_offender_id: indeterminate_without_ted.offender_no,
                       team: build(:team, local_divisional_unit: ldu))

    create(:allocation, nomis_offender_id: indeterminate_without_ted.offender_no)

    allow(OffenderService).to receive(:get_offender).and_return(indeterminate_without_ted)
    indeterminate_without_ted.load_case_information(case_info)

    expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
    described_class.perform_now(ldu)
  end

  context 'when no COM assigned' do
    let(:case_info) do
      create(:case_information, nomis_offender_id: determinate_offender.offender_no,
                       team: build(:team, local_divisional_unit: ldu))
    end

    before do
      allow(OffenderService).to receive(:get_offender).and_return(determinate_offender)
    end

    it 'does not send emails for offenders whose are not yet approaching handover' do
      create(:allocation, nomis_offender_id: determinate_offender.offender_no)
      determinate_offender.load_case_information(case_info)

      expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
      described_class.perform_now(ldu)
    end

    it 'does not send emails for offenders when their handover date is overdue by less than a week' do
      create(:allocation, nomis_offender_id: determinate_offender.offender_no)
      determinate_offender.load_case_information(case_info)

      expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)

      today = determinate_offender.handover_start_date + 5.days
      Timecop.travel today do
        described_class.perform_now(ldu)
      end
    end

    it 'does not send emails for offenders when their handover date is overdue by more than a week' do
      create(:allocation, nomis_offender_id: determinate_offender.offender_no)
      determinate_offender.load_case_information(case_info)

      expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)

      today = determinate_offender.handover_start_date + 10.days
      Timecop.travel today do
        described_class.perform_now(ldu)
      end
    end

    context 'when handover date is exactly one week overdue' do
      let(:today) { determinate_offender.handover_start_date + 1.week }

      it 'sends emails for unallocated offenders' do
        prison_code = Prison.new("LEI")
        allow(Prison).to receive(:active).and_return([prison_code])
        allow(PrisonOffenderManagerService).to receive(:get_pom_at).and_return(nil)

        determinate_offender.load_case_information(case_info)

        expect_any_instance_of(CommunityMailer)
        .to receive(:urgent_pipeline_to_community)
            .with(
              nomis_offender_id: determinate_offender.offender_no,
              offender_name: determinate_offender.full_name,
              offender_crn: determinate_offender.crn,
              ldu_email: determinate_offender.ldu_email_address,
              sentence_type: "Determinate",
              prison: "HMP Leeds",
              start_date: determinate_offender.handover_start_date,
              responsibility_handover_date: determinate_offender.responsibility_handover_date,
              pom_name: "This offender does not have an allocated POM",
              pom_email: ""
              ).and_call_original

        Timecop.travel today do
          described_class.perform_now(ldu)
        end
      end

      it 'sends emails for allocated offenders' do
        pom = build(:pom)
        allow(PrisonOffenderManagerService).to receive(:get_pom_at).and_return(pom)

        create(:allocation, nomis_offender_id: determinate_offender.offender_no,
               primary_pom_nomis_id: pom.staff_id,
               primary_pom_name: pom.full_name)

        determinate_offender.load_case_information(case_info)

        expect_any_instance_of(CommunityMailer)
        .to receive(:urgent_pipeline_to_community)
            .with(
              nomis_offender_id: determinate_offender.offender_no,
              offender_name: determinate_offender.full_name,
              offender_crn: determinate_offender.crn,
              ldu_email: determinate_offender.ldu_email_address,
              sentence_type: "Determinate",
              prison: "HMP Leeds",
              start_date: determinate_offender.handover_start_date,
              responsibility_handover_date: determinate_offender.responsibility_handover_date,
              pom_name: pom.full_name,
              pom_email: pom.email_address
              ).and_call_original

        Timecop.travel today do
          described_class.perform_now(ldu)
        end
      end
    end
  end

  def build_offender(release_date = nil, prison = 'LEI', sentence_type:, ard_crd_release:, ted:)
    build(:offender, sentence_type, latestLocationId: prison,
          sentence: build(:sentence_detail,
                          sentenceStartDate: Time.zone.today - 11.months,
                          conditionalReleaseDate: ard_crd_release,
                          automaticReleaseDate: ard_crd_release,
                          releaseDate: release_date,
                          tariffDate: ted))
  end
end
