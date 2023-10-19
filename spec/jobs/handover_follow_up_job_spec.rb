require 'rails_helper'

RSpec.describe HandoverFollowUpJob, type: :job do
  shared_context 'with expected behaviour' do
    let(:offender) { build(:mpc_offender, prison: active_prison, offender: case_info.offender, prison_record: api_offender) }
    let(:api_offender) do
      build_api_offender(Time.zone.today + 12.months,
                         sentence_type: :determinate,
                         ard_crd_release: Time.zone.today + 12.months,
                         ted: nil)
    end

    let(:offender_no) { api_offender.offender_no }

    let(:pom) { build(:pom) }

    # This prison is active because we give it an allocation in the `before` test setup block
    let(:active_prison) { create(:prison) }

    let(:case_info) { build(:case_information, offender: build(:offender, nomis_offender_id: offender_no)) }

    let(:today) { Time.zone.today }

    before do
      Timecop.travel today
      allow_any_instance_of(Prison).to receive(:get_single_pom).and_return(pom)
      allow(OffenderService).to receive(:get_offender).and_return(offender)

      # Create an unrelated allocation so that active_prison counts as active
      create(:allocation_history, prison: active_prison.code)
    end

    let!(:allocation) do
      create(:allocation_history,
             prison: active_prison.code,
             nomis_offender_id: offender_no,
             primary_pom_nomis_id: pom.staff_id,
             primary_pom_name: pom.full_name)
    end

    after do
      Timecop.return
    end

    context 'when the offender does not exist in NOMIS' do
      let(:offender) { nil }
      let(:offender_no) do
        # Use offender factory to give a 'realistic' offender number
        build(:hmpps_api_offender).offender_no
      end

      it 'does not send email' do
        expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
        expect { described_class.perform_now(ldu) }.not_to raise_error
      end
    end

    context 'when the offender exists in NOMIS' do
      context 'when the offender is un-sentenced' do
        let(:api_offender) do
          build_api_offender(sentence_type: :determinate, ard_crd_release: nil, ted: nil)
        end
        let(:today) { Time.zone.today }

        it 'does not send email' do
          expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
          described_class.perform_now(ldu)
        end
      end

      context 'when the offender already has a COM allocated' do
        let(:today) { offender.handover_start_date + 1.week }
        let(:case_info) do
          create(:case_information, :with_com,
                 offender: build(:offender, nomis_offender_id: offender_no))
        end

        it 'does not send email' do
          expect_any_instance_of(CommunityMailer).not_to receive(:urgent_pipeline_to_community)
          described_class.perform_now(ldu)
        end
      end

      context 'when the offender does not have a handover_start_date' do
        let(:api_offender) do
          build_api_offender(Time.zone.today + 10.months,
                             sentence_type: :indeterminate,
                             ard_crd_release: nil,
                             ted: nil)
        end
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
          let!(:allocation) { create(:allocation_history, :release, prison: active_prison.code, nomis_offender_id: offender_no) }

          it 'emails the LDU' do
            mailer = double(:mailer)
            expect(CommunityMailer).to receive(:with)
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
                                           pom_email: "")
                                         .and_return(double(urgent_pipeline_to_community: mailer))
            expect(mailer).to receive(:deliver_now)
            described_class.perform_now(ldu)
          end
        end

        context 'when the offender has a POM allocated' do
          it 'emails the LDU' do
            mailer = double(:mailer)
            expect(CommunityMailer).to receive(:with)
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
                                           pom_email: pom.email_address)
                                         .and_return(double(urgent_pipeline_to_community: mailer))
            expect(mailer).to receive(:deliver_now)
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

  def build_api_offender(release_date = nil, sentence_type:, ard_crd_release:, ted:, prison: nil)
    prison ||= active_prison
    build(:hmpps_api_offender, prisonId: prison.code,
                               sentence: attributes_for(:sentence_detail,
                                                        sentence_type,
                                                        sentenceStartDate: Time.zone.today - 11.months,
                                                        conditionalReleaseDate: ard_crd_release,
                                                        automaticReleaseDate: ard_crd_release,
                                                        releaseDate: release_date,
                                                        tariffDate: ted))
  end
end
