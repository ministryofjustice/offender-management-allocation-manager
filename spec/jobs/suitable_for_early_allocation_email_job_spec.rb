require 'rails_helper'

RSpec.describe SuitableForEarlyAllocationEmailJob, type: :job do
  let(:pom) { build(:pom) }

  let(:offender) do
    build(:offender, latestLocationId: 'LEI',
          sentence: build(:sentence_detail,
                          :determinate,
                          sentenceStartDate: Time.zone.today - 10.months,
                          conditionalReleaseDate: release_date,
                          automaticReleaseDate: release_date,
                          releaseDate: release_date,
                          tariffDate: nil))
  end

  before do
    create(:case_information, nomis_offender_id: offender.offender_no)
    allow(OffenderService).to receive(:get_offender).and_return(offender)
  end

  context 'when offender is not allocated to a POM' do
    let(:release_date) { Time.zone.today + 17.months }

    it 'does not send email' do
      create(:early_allocation, created_at: Time.zone.today - 9.months, updated_at: Time.zone.today - 9.months,
             created_within_referral_window: false, nomis_offender_id: offender.offender_no)

      expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
      described_class.perform_now(offender.offender_no)
    end
  end

  context 'when offender is allocated to a POM' do
    before do
      create(:allocation, nomis_offender_id: offender.offender_no, primary_pom_nomis_id: pom.staff_id, primary_pom_name: pom.full_name)
    end

    context 'when form created outside of the referral window (more than 18 months to release)' do
      context 'when form outcome is ineligible' do
        let(:release_date) { Time.zone.today + 28.months }

        it 'does not send email' do
          create(:early_allocation, :ineligible, created_within_referral_window: false, nomis_offender_id: offender.offender_no)

          expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
          described_class.perform_now(offender.offender_no)
        end
      end

      context 'when offender not found in NOMIS' do
        let(:release_date) { Time.zone.today + 17.months }

        before do
          allow(OffenderService).to receive(:get_offender).and_return(nil)
        end

        it 'does not send email' do
          create(:early_allocation, created_at: Time.zone.today - 9.months, updated_at: Time.zone.today - 9.months,
                 created_within_referral_window: false, nomis_offender_id:  offender.offender_no)

          expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
          described_class.perform_now(offender.offender_no)
        end
      end

      context 'when offender has more than 18 months of sentence remaining' do
        let(:release_date) { Time.zone.today + 19.months }

        it 'does not send email' do
          create(:early_allocation, created_at: Time.zone.today - 9.months, updated_at: Time.zone.today - 9.months,
                 created_within_referral_window: false, nomis_offender_id:  offender.offender_no)

          expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
          described_class.perform_now(offender.offender_no)
        end
      end

      context 'when offender has 18 months or less of sentence remaining' do
        before do
          allow(PrisonOffenderManagerService).to receive(:get_pom_at).and_return(pom)
        end

        context 'when no previous Early Allocation reminder email sent for this offender' do
          let(:release_date) { Time.zone.today + 18.months }

          it 'sends email' do
            create(:early_allocation, created_at: Time.zone.today - 9.months, updated_at: Time.zone.today - 9.months,
                   created_within_referral_window: false, nomis_offender_id:  offender.offender_no)

            expect_any_instance_of(EarlyAllocationMailer).to receive(:review_early_allocation).with(
              email: pom.email_address,
              prisoner_name: offender.full_name,
              start_page_link: "http://localhost:3000/prisons/#{offender.prison_id}/prisoners/#{offender.offender_no}/early_allocations",
              equip_guidance_link: "https://equip-portal.rocstac.com/CtrlWebIsapi.dll/?__id=webDiagram.show&map=0%3A9A63E167DE4B400EA07F81A9271E1944&dgm=4F984B45CBC447B1A304B2FFECABB777"
            ).and_call_original

            expect { described_class.perform_now(offender.offender_no) }.to change(EmailHistory, :count).by(1)
          end
        end

        context 'when there are previous Early Allocation reminders emails sent for this offenders' do
          let(:release_date) { Time.zone.today + 17.months }

          context 'when the email relates to the current sentence' do
            before do
              create(:email_history, :suitable_early_allocation, nomis_offender_id: offender.offender_no)
            end

            it 'does not send email if email previously sent' do
              create(:early_allocation, created_at: Time.zone.today - 9.months, updated_at: Time.zone.today - 9.months,
                     created_within_referral_window: false, nomis_offender_id:  offender.offender_no)

              expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
              expect { described_class.perform_now(offender.offender_no) }.to change(EmailHistory, :count).by(0)
            end
          end

          context 'when the email relates to the offenders previous sentence' do
            before do
              create(:email_history, :suitable_early_allocation, nomis_offender_id: offender.offender_no, created_at: Time.zone.today - 3.years)
            end

            it 'does send email' do
              create(:early_allocation, created_at: Time.zone.today - 9.months, updated_at: Time.zone.today - 9.months,
                     created_within_referral_window: false, nomis_offender_id:  offender.offender_no)
              expect_any_instance_of(EarlyAllocationMailer).to receive(:review_early_allocation).with(
                email: pom.email_address,
                prisoner_name: offender.full_name,
                start_page_link: "http://localhost:3000/prisons/#{offender.prison_id}/prisoners/#{offender.offender_no}/early_allocations",
                equip_guidance_link: "https://equip-portal.rocstac.com/CtrlWebIsapi.dll/?__id=webDiagram.show&map=0%3A9A63E167DE4B400EA07F81A9271E1944&dgm=4F984B45CBC447B1A304B2FFECABB777"
                ).and_call_original

              expect { described_class.perform_now(offender.offender_no) }.to change(EmailHistory, :count).by(1)
            end
          end
        end
      end
    end
  end
end
