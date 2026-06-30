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
    allow(OffenderService).to receive(:get_offender)
      .with(api_offender.offender_no, fetch_complexities: false, fetch_categories: false, fetch_movements: false)
      .and_return(offender)
  end

  context 'when offender is not allocated to a POM' do
    let(:release_date) { Time.zone.today + 17.months }

    it 'does not send email' do
      expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
      described_class.perform_now(api_offender.offender_no)
    end
  end

  context 'when offender is allocated to a POM' do
    before do
      create(:allocation_history, prison: prison.code, nomis_offender_id: api_offender.offender_no, primary_pom_nomis_id: pom.staff_id, primary_pom_name: pom.full_name)
    end

    context 'when offender has transferred but allocation has not been updated' do
      let(:release_date) { Time.zone.today + 17.months }
      let(:other_prison) { create(:prison) }

      before do
        transferred_api_offender = build(:hmpps_api_offender, prisonId: other_prison.code,
                                                              sentence: attributes_for(:sentence_detail,
                                                                                       :determinate,
                                                                                       sentenceStartDate: Time.zone.today - 10.months,
                                                                                       conditionalReleaseDate: release_date,
                                                                                       automaticReleaseDate: release_date,
                                                                                       releaseDate: release_date,
                                                                                       tariffDate: nil))
        case_info = CaseInformation.find_by(nomis_offender_id: api_offender.offender_no)
        transferred_offender = build(:mpc_offender, prison: other_prison, offender: case_info.offender, prison_record: transferred_api_offender)
        allow(OffenderService).to receive(:get_offender)
          .with(api_offender.offender_no, fetch_complexities: false, fetch_categories: false, fetch_movements: false)
          .and_return(transferred_offender)
      end

      it 'does not send email' do
        expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
        described_class.perform_now(api_offender.offender_no)
      end
    end

    context 'when offender not found in NOMIS' do
      let(:release_date) { Time.zone.today + 17.months }

      before do
        allow(OffenderService).to receive(:get_offender)
          .with(api_offender.offender_no, fetch_complexities: false, fetch_categories: false, fetch_movements: false)
          .and_return(nil)
      end

      it 'does not send email' do
        expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
        described_class.perform_now(api_offender.offender_no)
      end
    end

    context 'when offender has more than 18 months of sentence remaining' do
      let(:release_date) { Time.zone.today + 19.months }

      it 'does not send email' do
        expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
        described_class.perform_now(api_offender.offender_no)
      end
    end

    context 'when offender is within the early allocation window' do
      before do
        allow_any_instance_of(Prison).to receive(:get_single_pom).and_return(pom)
      end

      context 'when no previous early allocation reminder email has been sent' do
        let(:release_date) { Time.zone.today + 18.months }

        it 'sends the email' do
          mailer = double(:mailer)
          expect(EarlyAllocationMailer).to receive(:with)
            .with(
              email: pom.email_address,
              prisoner_name: api_offender.full_name,
              prisoner_number: api_offender.offender_no,
              prison_name: prison.name,
              start_page_link: "http://localhost:3000/prisons/#{api_offender.prison_id}/prisoners/#{api_offender.offender_no}/early_allocations",
              equip_guidance_link: described_class::EQUIP_URL
            )
            .and_return(double(review_early_allocation: mailer))
          expect(mailer).to receive(:deliver_now)
          described_class.perform_now(api_offender.offender_no)
        end
      end

      context 'when an email was already sent during the current sentence' do
        let(:release_date) { Time.zone.today + 17.months }

        before do
          create(:email_history, :suitable_early_allocation, nomis_offender_id: api_offender.offender_no)
        end

        it 'does not send email' do
          expect_any_instance_of(EarlyAllocationMailer).not_to receive(:review_early_allocation)
          expect { described_class.perform_now(api_offender.offender_no) }.not_to change(EmailHistory, :count)
        end
      end

      context 'when an email was sent before the current sentence started' do
        let(:release_date) { Time.zone.today + 17.months }

        before do
          create(:email_history, :suitable_early_allocation, nomis_offender_id: api_offender.offender_no, created_at: Time.zone.today - 3.years)
        end

        it 'sends the email' do
          mailer = double(:mailer)
          expect(EarlyAllocationMailer).to receive(:with)
            .with(
              email: pom.email_address,
              prisoner_name: api_offender.full_name,
              prisoner_number: api_offender.offender_no,
              prison_name: prison.name,
              start_page_link: "http://localhost:3000/prisons/#{api_offender.prison_id}/prisoners/#{api_offender.offender_no}/early_allocations",
              equip_guidance_link: described_class::EQUIP_URL
            )
            .and_return(double(review_early_allocation: mailer))
          expect(mailer).to receive(:deliver_now)
          described_class.perform_now(api_offender.offender_no)
        end
      end
    end
  end
end
