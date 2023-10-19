require 'rails_helper'

RSpec.describe SuitableForEarlyAllocationEmailJob, type: :job do
  let(:pom) { build(:pom) }
  let!(:prison) { create(:prison) }

  let(:api_offender) do
    build(:hmpps_api_offender, prisonId: prison.code,
                               sentence: attributes_for(:sentence_detail,
                                                        :determinate,
                                                        sentenceStartDate: Time.zone.today - 10.months,
                                                        conditionalReleaseDate: release_date,
                                                        automaticReleaseDate: release_date,
                                                        releaseDate: release_date,
                                                        tariffDate: nil))
  end

  before do
    case_info = create(:case_information, offender: build(:offender, nomis_offender_id: api_offender.offender_no))
    offender = build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender)
    allow(OffenderService).to receive(:get_offender).and_return(offender)
  end

  context 'when offender is not allocated to a POM' do
    let(:release_date) { Time.zone.today + 17.months }

    it 'does not send email' do
      create(:early_allocation, created_at: Time.zone.today - 9.months, updated_at: Time.zone.today - 9.months,
                                created_within_referral_window: false, nomis_offender_id: api_offender.offender_no)

      expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
      described_class.perform_now(api_offender.offender_no)
    end
  end

  context 'when offender is allocated to a POM' do
    before do
      create(:allocation_history, prison: prison.code, nomis_offender_id: api_offender.offender_no, primary_pom_nomis_id: pom.staff_id, primary_pom_name: pom.full_name)
    end

    context 'when form created outside of the referral window (more than 18 months to release)' do
      context 'when form outcome is ineligible' do
        let(:release_date) { Time.zone.today + 28.months }

        it 'does not send email' do
          create(:early_allocation, :ineligible, created_within_referral_window: false, nomis_offender_id: api_offender.offender_no)

          expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
          described_class.perform_now(api_offender.offender_no)
        end
      end

      context 'when offender not found in NOMIS' do
        let(:release_date) { Time.zone.today + 17.months }

        before do
          allow(OffenderService).to receive(:get_offender).and_return(nil)
        end

        it 'does not send email' do
          create(:early_allocation, created_at: Time.zone.today - 9.months, updated_at: Time.zone.today - 9.months,
                                    created_within_referral_window: false, nomis_offender_id:  api_offender.offender_no)

          expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
          described_class.perform_now(api_offender.offender_no)
        end
      end

      context 'when offender has more than 18 months of sentence remaining' do
        let(:release_date) { Time.zone.today + 19.months }

        it 'does not send email' do
          create(:early_allocation, created_at: Time.zone.today - 9.months, updated_at: Time.zone.today - 9.months,
                                    created_within_referral_window: false, nomis_offender_id:  api_offender.offender_no)

          expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
          described_class.perform_now(api_offender.offender_no)
        end
      end

      context 'when offender has 18 months or less of sentence remaining' do
        before do
          allow_any_instance_of(Prison).to receive(:get_single_pom).and_return(pom)
        end

        context 'when no previous Early Allocation reminder email sent for this offender' do
          let(:release_date) { Time.zone.today + 18.months }

          it 'sends email' do
            create(:early_allocation, created_at: Time.zone.today - 9.months, updated_at: Time.zone.today - 9.months,
                                      created_within_referral_window: false, nomis_offender_id:  api_offender.offender_no)

            mailer = double(:mailer)
            expect(EarlyAllocationMailer).to receive(:with)
                                         .with(
                                           email: pom.email_address,
                                           prisoner_name: api_offender.full_name,
                                           start_page_link: "http://localhost:3000/prisons/#{api_offender.prison_id}/prisoners/#{api_offender.offender_no}/early_allocations",
                                           equip_guidance_link: "https://equip-portal.rocstac.com/CtrlWebIsapi.dll/?__id=webDiagram.show&map=0%3A9A63E167DE4B400EA07F81A9271E1944&dgm=4F984B45CBC447B1A304B2FFECABB777"
                                         )
                                         .and_return(double(review_early_allocation: mailer))
            expect(mailer).to receive(:deliver_now)

            expect { described_class.perform_now(api_offender.offender_no) }.to change(EmailHistory, :count).by(1)
          end
        end

        context 'when there are previous Early Allocation reminders emails sent for this offenders' do
          let(:release_date) { Time.zone.today + 17.months }

          context 'when the email relates to the current sentence' do
            before do
              create(:email_history, :suitable_early_allocation, nomis_offender_id: api_offender.offender_no)
            end

            it 'does not send email if email previously sent' do
              create(:early_allocation, created_at: Time.zone.today - 9.months, updated_at: Time.zone.today - 9.months,
                                        created_within_referral_window: false, nomis_offender_id:  api_offender.offender_no)

              expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
              expect { described_class.perform_now(api_offender.offender_no) }.to change(EmailHistory, :count).by(0)
            end
          end

          context 'when the email relates to the offenders previous sentence' do
            before do
              create(:email_history, :suitable_early_allocation, nomis_offender_id: api_offender.offender_no, created_at: Time.zone.today - 3.years)
            end

            it 'does send email' do
              create(:early_allocation, created_at: Time.zone.today - 9.months, updated_at: Time.zone.today - 9.months,
                                        created_within_referral_window: false, nomis_offender_id:  api_offender.offender_no)

              mailer = double(:mailer)
              expect(EarlyAllocationMailer).to receive(:with)
                                                 .with(
                                                   email: pom.email_address,
                                                   prisoner_name: api_offender.full_name,
                                                   start_page_link: "http://localhost:3000/prisons/#{api_offender.prison_id}/prisoners/#{api_offender.offender_no}/early_allocations",
                                                   equip_guidance_link: "https://equip-portal.rocstac.com/CtrlWebIsapi.dll/?__id=webDiagram.show&map=0%3A9A63E167DE4B400EA07F81A9271E1944&dgm=4F984B45CBC447B1A304B2FFECABB777"
                                                 )
                                                 .and_return(double(review_early_allocation: mailer))
              expect(mailer).to receive(:deliver_now)
              expect { described_class.perform_now(api_offender.offender_no) }.to change(EmailHistory, :count).by(1)
            end
          end
        end
      end
    end
  end
end
