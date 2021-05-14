require 'rails_helper'

RSpec.describe HandoverFollowUpJob, type: :job do
  shared_context 'with expected behaviour' do
    let(:offender) do
      build_offender(Time.zone.today + 8.months,
                     sentence_type: :determinate,
                     ard_crd_release: Time.zone.today + 8.months,
                     ted: nil)
    end

    let(:offender_no) { offender.offender_no }

    let(:pom) { build(:pom) }

    # This prison is active because we give it an allocation in the `before` test setup block
    let(:active_prison) { build(:prison) }

    # This prison is inactive because we don't give it any allocations
    let(:inactive_prison) { build(:prison) }

    let(:case_info) { build(:case_information, nomis_offender_id: offender_no) }

    let!(:allocation) {
      create(:allocation,
             prison: active_prison.code,
             nomis_offender_id: offender_no,
             primary_pom_nomis_id: pom.staff_id,
             primary_pom_name: pom.full_name)
    }

    let(:today) { Time.zone.today }

    before do
      Timecop.travel today

      allow(PrisonOffenderManagerService).to receive(:get_pom_at).and_return(pom)

      allow(OffenderService).to receive(:get_offender).and_return(offender)
      offender.load_case_information(case_info) unless offender.nil?

      # Create an unrelated allocation so that active_prison counts as active
      create(:allocation, prison: active_prison.code)
    end

    after do
      Timecop.return
    end

    context 'when the offender does not exist in NOMIS' do
      let(:offender) { nil }
      let(:offender_no) {
        # Use offender factory to give a 'realistic' offender number
        build(:offender).offender_no
      }

      it 'does not send email' do
        expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
        expect { described_class.perform_now(ldu) }.not_to raise_error
      end
    end

    context 'when the offender exists in NOMIS' do
      let(:today) { offender.handover_start_date + 1.week }

      context 'when the offender is not in an active prison' do
        let(:release_date) { Time.zone.today + 8.months }
        let(:offender) {
          build_offender(release_date,
                         prison: inactive_prison,
                         sentence_type: :determinate,
                         ard_crd_release: release_date,
                         ted: nil)
        }

        it 'does not send email' do
          expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
          described_class.perform_now(ldu)
        end
      end

      context 'when the offender is un-sentenced' do
        let(:offender) {
          build_offender(sentence_type: :determinate, ard_crd_release: nil, ted: nil)
        }
        let(:today) { Time.zone.today }

        it 'does not send email' do
          expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
          described_class.perform_now(ldu)
        end
      end

      context 'when the offender already has a COM allocated' do
        let(:case_info) { create(:case_information, :with_com, nomis_offender_id: offender_no) }

        it 'does not send email' do
          expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
          described_class.perform_now(ldu)
        end
      end

      context 'when the offender does not have a handover_start_date' do
        let(:offender) {
          build_offender(Time.zone.today + 10.months,
                         sentence_type: :indeterminate,
                         ard_crd_release: nil,
                         ted: nil)
        }
        let(:today) { Time.zone.today }

        it 'does not send email' do
          expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
          described_class.perform_now(ldu)
        end
      end

      context 'when start of handover is in the future' do
        let(:today) { offender.handover_start_date - 1.day }

        it 'does not send email' do
          expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
          described_class.perform_now(ldu)
        end
      end

      context 'when handover started less than 1 week ago' do
        let(:today) { offender.handover_start_date + 6.days }

        it 'does not send email' do
          expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
          described_class.perform_now(ldu)
        end
      end

      context 'when handover started more than 1 week ago' do
        let(:today) { offender.handover_start_date + 8.days }

        it 'does not send email' do
          expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
          described_class.perform_now(ldu)
        end
      end

      context 'when handover started exactly 1 week ago' do
        let(:today) { offender.handover_start_date + 1.week }

        context 'when the offender does not have a POM allocated' do
          let!(:allocation) { create(:allocation, :release, nomis_offender_id: offender_no) }

          it 'emails the LDU' do
            expect_any_instance_of(CommunityMailer)
              .to receive(:urgent_pipeline_to_community)
                    .with(
                      nomis_offender_id: offender_no,
                      offender_name: offender.full_name,
                      offender_crn: offender.crn,
                      ldu_email: offender.ldu_email_address,
                      sentence_type: "Determinate",
                      prison: active_prison.name,
                      start_date: offender.handover_start_date,
                      responsibility_handover_date: offender.responsibility_handover_date,
                      pom_name: "This offender does not have an allocated POM",
                      pom_email: ""
                    ).and_call_original

            described_class.perform_now(ldu)
          end
        end

        context 'when the offender has a POM allocated' do
          it 'emails the LDU' do
            expect_any_instance_of(CommunityMailer)
              .to receive(:urgent_pipeline_to_community)
                    .with(
                      nomis_offender_id: offender_no,
                      offender_name: offender.full_name,
                      offender_crn: offender.crn,
                      ldu_email: offender.ldu_email_address,
                      sentence_type: "Determinate",
                      prison: active_prison.name,
                      start_date: offender.handover_start_date,
                      responsibility_handover_date: offender.responsibility_handover_date,
                      pom_name: pom.full_name,
                      pom_email: pom.email_address
                    ).and_call_original

            described_class.perform_now(ldu)
          end
        end
      end
    end
  end

  context 'when given a LocalDeliveryUnit' do
    let!(:ldu) { create(:local_delivery_unit, case_information: [case_info]) }

    include_context 'with expected behaviour'
  end

private

  def build_offender(release_date = nil, prison: nil, sentence_type:, ard_crd_release:, ted:)
    prison = prison || active_prison
    build(:offender, latestLocationId: prison.code,
          sentence: build(:sentence_detail,
                          sentence_type,
                          sentenceStartDate: Time.zone.today - 11.months,
                          conditionalReleaseDate: ard_crd_release,
                          automaticReleaseDate: ard_crd_release,
                          releaseDate: release_date,
                          tariffDate: ted))
  end
end
