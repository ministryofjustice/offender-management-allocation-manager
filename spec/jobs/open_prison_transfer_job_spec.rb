# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenPrisonTransferJob, type: :job do
  include ActiveJob::TestHelper

  let(:nomis_offender_id) { 'G3462VT' }
  let(:determinate_nomis_offender) {
    build(:nomis_offender, offenderNo: nomis_offender_id,
          agencyId: open_prison_code,
          sentence: attributes_for(:sentence_detail, :handover_in_8_days))
  }
  let(:indeterminate_nomis_offender) {
    build(:nomis_offender, :indeterminate, offenderNo: nomis_offender_id,
          agencyId: open_prison_code)
  }
  # Default to a Determinate offender – change by setting this to `indeterminate_nomis_offender`
  let(:nomis_offender) { determinate_nomis_offender }
  let(:offender) { OffenderService.get_offender(nomis_offender_id) }

  let(:nomis_staff_id) { 485_637 }
  let(:other_staff_id) { 485_636 }

  let(:closed_prison_code) { 'LEI' }
  let(:closed_prison_name) { PrisonService.name_for(closed_prison_code) }
  let(:open_prison_code) { 'HDI' }
  let(:open_prison_name) { PrisonService.name_for(open_prison_code) }

  let(:poms) {
    [build(:pom,
           staffId: nomis_staff_id,
           firstName: 'Firstname',
           lastName: 'Lastname',
           position: RecommendationService::PRISON_POM,
           emails: ['pom@localhost.local']
     )]
  }

  let(:movement) {
    {
      offenderNo: nomis_offender_id,
      fromAgency: closed_prison_code,
      toAgency: open_prison_code,
      movementType: "TRN",
      directionCode: "IN",
      movementDate: Time.zone.today.iso8601
    }.stringify_keys
  }
  let(:movement_json) { HmppsApi::Movement.from_json(movement).to_json }

  # Set the current date by changing the value of `today`
  let(:today) { Time.zone.today }

  before { Timecop.travel(today) }

  after { Timecop.return }

  before do
    stub_auth_token
    stub_poms(closed_prison_code, poms)
    stub_pom poms.first
    stub_offender(nomis_offender) if nomis_offender.present?
    stub_movements([movement])
  end

  context 'when the offender could not be found' do
    let(:nomis_offender) { nil }

    before do
      stub_non_existent_offender(nomis_offender_id)
    end

    it 'does not send an email' do
      described_class.perform_now(movement_json)
      email_job = enqueued_jobs.first
      expect(email_job).to be_nil
    end
  end

  context 'when offender is not NPS' do
    let!(:case_info) {
      create(:case_information, :crc, nomis_offender_id: nomis_offender_id)
    }

    it 'does not send an email' do
      described_class.perform_now(movement_json)
      email_job = enqueued_jobs.first
      expect(email_job).to be_nil
    end
  end

  context 'when the LDU email address is not known' do
    let!(:case_info) {
      create(:case_information, :nps, nomis_offender_id: nomis_offender_id,
             team: build(:team, local_divisional_unit: build(:local_divisional_unit, email_address: nil))
      )
    }

    it 'does not send an email' do
      described_class.perform_now(movement_json)
      email_job = enqueued_jobs.first
      expect(email_job).to be_nil
    end
  end

  describe "before OMIC launches in Open Prisons" do
    # The day before Open Prison policy starts
    let(:today) { HandoverDateService::OPEN_PRISON_POLICY_START_DATE - 1.day }

    context 'when there is no previous allocation' do
      let!(:case_info) {
        create(:case_information, :nps, nomis_offender_id: nomis_offender_id,
               local_delivery_unit: build(:local_delivery_unit)
        )
      }

      it 'asks the LDU to allocate a Responsible COM' do
        expect(CommunityMailer).to receive(:open_prison_prepolicy_responsible_com_needed)
                               .with(hash_including(
                                       prisoner_number: nomis_offender_id,
                                       prisoner_name: offender.full_name,
                                       prisoner_crn: offender.crn,
                                       previous_pom_name: 'N/A',
                                       previous_pom_email: 'N/A',
                                       prison_name: open_prison_name,
                                       previous_prison_name: closed_prison_name
                                     )).and_call_original

        described_class.perform_now(movement_json)
      end
    end

    context 'when there is a previous allocation' do
      let!(:case_info) {
        create(:case_information, :nps, nomis_offender_id: nomis_offender_id,
               local_delivery_unit: build(:local_delivery_unit)
        )
      }

      # Create an allocation where the offender is allocated, and then deallocate so we can
      # test finding the last pom that was allocated to this offender ....
      let!(:allocation) {
        create(:allocation, nomis_offender_id: nomis_offender_id,
               primary_pom_nomis_id: other_staff_id, primary_pom_name: 'Primary POMName',
               prison: closed_prison_code
        ).tap { |alloc|
          alloc.update(primary_pom_nomis_id: nomis_staff_id)
          alloc.dealloate_offender_after_transfer
        }
      }

      it 'includes previous POM details in the email' do
        expect(CommunityMailer).to receive(:open_prison_prepolicy_responsible_com_needed)
                               .with(hash_including(
                                       prisoner_number: nomis_offender_id,
                                       prisoner_name: offender.full_name,
                                       prisoner_crn: offender.crn,
                                       previous_pom_name: 'Primary POMName',
                                       previous_pom_email: 'pom@localhost.local',
                                       prison_name: open_prison_name,
                                       previous_prison_name: closed_prison_name
                                     )).and_call_original

        described_class.perform_now(movement_json)
      end
    end

    context "when a Welsh offender is transferred to Prescoed open prison" do
      let(:open_prison_code) { PrisonService::PRESCOED_CODE }

      let!(:case_info) {
        create(:case_information, :welsh, :nps, nomis_offender_id: nomis_offender_id,
               local_delivery_unit: build(:local_delivery_unit)
        )
      }

      # Create an allocation where the offender is allocated, and then deallocate so we can
      # test finding the last pom that was allocated to this offender ....
      let!(:allocation) {
        create(:allocation, nomis_offender_id: nomis_offender_id,
               primary_pom_nomis_id: other_staff_id, primary_pom_name: 'Primary POMName',
               prison: closed_prison_code
        ).tap { |alloc|
          alloc.update(primary_pom_nomis_id: nomis_staff_id)
          alloc.dealloate_offender_after_transfer
        }
      }

      context 'with an indeterminate offender' do
        let(:nomis_offender) { indeterminate_nomis_offender }

        it 'asks the LDU to allocate a Supporting COM' do
          expect(CommunityMailer).to receive(:open_prison_supporting_com_needed)
                                       .with(hash_including(
                                               prisoner_number: nomis_offender_id,
                                               prisoner_name: offender.full_name,
                                               prisoner_crn: case_info.crn,
                                               ldu_email: offender.ldu_email_address,
                                               prison_name: open_prison_name,
                                             )).and_call_original

          expect { described_class.perform_now(movement_json) }.to change(EmailHistory, :count).by(1)
        end
      end

      context "with a determinate offender" do
        it 'does not send an email to the LDU' do
          expect_any_instance_of(CommunityMailer).not_to receive(:open_prison_prepolicy_responsible_com_needed)
          expect_any_instance_of(CommunityMailer).not_to receive(:open_prison_supporting_com_needed)
          expect { described_class.perform_now(movement_json) }.to change(EmailHistory, :count).by(0)
        end
      end
    end
  end

  describe "after OMIC has launched in Open Prisons" do
    # The day Open Prison policy starts
    let(:today) { HandoverDateService::OPEN_PRISON_POLICY_START_DATE }

    context 'when the offender is NPS Determinate' do
      let!(:case_info) {
        create(:case_information, :nps, nomis_offender_id: nomis_offender_id,
               local_delivery_unit: build(:local_delivery_unit)
        )
      }

      it "does not send an email - a COM isn't needed yet" do
        described_class.perform_now(movement_json)
        email_job = enqueued_jobs.first
        expect(email_job).to be_nil
        expect(offender.com_responsible?).to eq(false)
        expect(offender.com_supporting?).to eq(false)
      end
    end

    context 'when the offender is CRC Determinate' do
      let!(:case_info) {
        create(:case_information, :crc, nomis_offender_id: nomis_offender_id,
               local_delivery_unit: build(:local_delivery_unit)
        )
      }

      it "does not send an email - a COM isn't needed yet" do
        described_class.perform_now(movement_json)
        email_job = enqueued_jobs.first
        expect(email_job).to be_nil
        expect(offender.com_responsible?).to eq(false)
        expect(offender.com_supporting?).to eq(false)
      end
    end

    context 'when the offender is NPS Indeterminate' do
      let(:nomis_offender) { indeterminate_nomis_offender }

      let!(:case_info) {
        create(:case_information, :nps, nomis_offender_id: nomis_offender_id,
               local_delivery_unit: build(:local_delivery_unit)
        )
      }

      it 'asks the LDU to allocate a Supporting COM' do
        expect(CommunityMailer).to receive(:open_prison_supporting_com_needed)
                                     .with(hash_including(
                                             prisoner_number: nomis_offender_id,
                                             prisoner_name: offender.full_name,
                                             prisoner_crn: case_info.crn,
                                             ldu_email: offender.ldu_email_address,
                                             prison_name: open_prison_name,
                                           )).and_call_original

        expect { described_class.perform_now(movement_json) }.to change(EmailHistory, :count).by(1)
      end
    end
  end
end
