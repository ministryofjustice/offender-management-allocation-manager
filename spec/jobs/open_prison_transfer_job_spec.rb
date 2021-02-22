require 'rails_helper'

RSpec.describe OpenPrisonTransferJob, type: :job do
  include ActiveJob::TestHelper

  let(:nomis_offender_id) { 'G3462VT' }
  let(:nomis_offender) { build(:nomis_offender, offenderNo: nomis_offender_id, latestLocationId: open_prison_code) }
  let(:offender) { OffenderService.get_offender(nomis_offender_id) }
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

  context 'when there is no previous allocation' do
    let!(:case_info) {
      create(:case_information, :nps, nomis_offender_id: nomis_offender_id,
             local_delivery_unit: build(:local_delivery_unit)
      )
    }

    it 'sends an email' do
      expect(PomMailer).to receive(:responsibility_override_open_prison)
                             .with(hash_including(
                                     prisoner_number: nomis_offender_id,
                                     prisoner_name: offender.full_name,
                                     responsible_pom_name: 'N/A',
                                     responsible_pom_email: 'N/A',
                                     prison_name: 'HMP/YOI Hatfield',
                                     previous_prison_name: 'HMP Leeds'
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
        alloc.offender_transferred
      }
    }

    it 'includes previous POM details in the email' do
      expect(PomMailer).to receive(:responsibility_override_open_prison)
                             .with(hash_including(
                                     prisoner_number: nomis_offender_id,
                                     prisoner_name: offender.full_name,
                                     responsible_pom_name: 'Primary POMName',
                                     responsible_pom_email: 'pom@localhost.local',
                                     prison_name: 'HMP/YOI Hatfield',
                                     previous_prison_name: 'HMP Leeds'
                                   )).and_call_original

      described_class.perform_now(movement_json)
    end
  end

  context "when a Welsh offender is transferred to Prescoed open prison" do
    let(:open_prison_code) { 'UPI' } # HMP Prescoed

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
        alloc.offender_transferred
      }
    }

    context 'with an indeterminate offender' do
      let(:nomis_offender) { build(:nomis_offender, :indeterminate, offenderNo: nomis_offender_id, latestLocationId: open_prison_code) }

      it 'sends an email to the LDU' do
        expect(CommunityMailer).to receive(:omic_open_prison_community_allocation)
                                     .with(hash_including(
                                             nomis_offender_id: nomis_offender_id,
                                             prisoner_name: offender.full_name,
                                             crn: case_info.crn,
                                             ldu_email: offender.ldu_email_address,
                                             prison: 'HMP/YOI Prescoed',
                                             pom_name: 'Primary POMName',
                                             pom_email: 'pom@localhost.local'
                                           )).and_call_original

        expect { described_class.perform_now(movement_json) }.to change(EmailHistory, :count).by(1)
      end
    end

    context "with a determinate offender" do
      it 'does not send an email to the LDU' do
        expect_any_instance_of(PomMailer).not_to receive(:responsibility_override_open_prison)
        expect_any_instance_of(CommunityMailer).not_to receive(:omic_open_prison_community_allocation)
        expect { described_class.perform_now(movement_json) }.to change(EmailHistory, :count).by(0)
      end
    end
  end
end
