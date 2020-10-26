require 'rails_helper'

RSpec.describe CalculatedHandoverDate, type: :model do
  subject { build(:calculated_handover_date) }

  let(:today) { Time.zone.today }

  before do
    allow(HmppsApi::CommunityApi).to receive(:set_handover_dates)
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:nomis_offender_id) }
    it { is_expected.to validate_uniqueness_of(:nomis_offender_id) }
    it { is_expected.to validate_presence_of(:reason) }
  end

  it { is_expected.to belong_to(:case_information) }

  it 'allows nil handover dates' do
    case_info = create(:case_information)
    com_responsibility = HandoverDateService::NO_HANDOVER_DATE

    record = described_class.create!(
      nomis_offender_id: case_info.nomis_offender_id,
      start_date: com_responsibility.start_date,
      handover_date: com_responsibility.handover_date,
      reason: com_responsibility.reason
    )

    record.reload
    expect(record.start_date).to be_nil
    expect(record.handover_date).to be_nil
    expect(record.reason).to eq('COM Responsibility')
  end

  describe "when nomis_offender_id is set but an associated case information record doesn't exist" do
    subject {
      build(:calculated_handover_date,
            case_information: nil,
            nomis_offender_id: "A1234BC"
      )
    }

    it 'is not valid' do
      expect(subject.valid?).to be(false)
      expect(subject.save).to be(false)
    end
  end

  describe '#recalculate_for(offender)' do
    let(:offender) { build(:offender) }
    let!(:case_info) { create(:case_information, :nps, nomis_offender_id: offender.offender_no) }

    before { offender.load_case_information(case_info) }

    describe "when calculated handover dates don't exist yet for the offender" do
      it 'creates a new record' do
        expect {
          described_class.recalculate_for(offender)
        }.to change(described_class, :count).from(0).to(1)

        record = described_class.find_by(nomis_offender_id: offender.offender_no)
        expect(record.start_date).to eq(offender.handover_start_date)
        expect(record.handover_date).to eq(offender.responsibility_handover_date)
        expect(record.reason).to eq(offender.handover_reason)
      end
    end

    describe 'when calculated handover dates already exist for the offender' do
      let!(:existing_record) {
        create(:calculated_handover_date,
               case_information: case_info,
               start_date: existing_start_date,
               handover_date: existing_handover_date,
               reason: existing_reason
        )
      }

      before do
        expect(existing_record.start_date).to eq(existing_start_date)
        expect(existing_record.handover_date).to eq(existing_handover_date)
        expect(existing_record.reason).to eq(existing_reason)
      end

      describe 'when the dates have changed' do
        let(:existing_start_date) { today + 1.week }
        let(:existing_handover_date) { existing_start_date + 7.months }
        let(:existing_reason) { 'CRC Case' }

        it 'updates the existing record' do
          described_class.recalculate_for(offender)

          existing_record.reload
          expect(existing_record.start_date).to eq(offender.handover_start_date)
          expect(existing_record.handover_date).to eq(offender.responsibility_handover_date)
          expect(existing_record.reason).to eq(offender.handover_reason)
        end
      end

      describe "when the dates haven't changed" do
        let(:existing_start_date) { offender.handover_start_date }
        let(:existing_handover_date) { offender.responsibility_handover_date }
        let(:existing_reason) { offender.handover_reason }

        it "does nothing" do
          old_updated_at = existing_record.updated_at

          travel_to(Time.zone.now + 15.minutes) do
            described_class.recalculate_for(offender)
          end

          new_updated_at = existing_record.reload.updated_at
          expect(new_updated_at).to eq(old_updated_at)
        end
      end
    end
  end

  describe 'after save' do
    subject {
      create(:calculated_handover_date,
             start_date: today + 1.day,
             handover_date: today + 3.months,
             reason: 'CRC Case'
      )
    }

    describe 'when the dates have changed' do
      before do
        # Change the handover dates
        subject.assign_attributes(
          start_date: today + 6.months,
          handover_date: today + 13.months,
          reason: 'NPS - MAPPA level unknown'
        )
      end

      it 'pushes them to nDelius' do
        expect(subject.changed?).to be(true)
        expect(HmppsApi::CommunityApi).to receive(:set_handover_dates).with(
          offender_no: subject.nomis_offender_id,
          handover_start_date: subject.start_date,
          responsibility_handover_date: subject.handover_date
        )
        subject.save!
      end
    end

    describe "when the dates haven't changed" do
      before do
        # Change the reason, but not the dates
        subject.reason = 'NPS - MAPPA level unknown'
      end

      it "doesn't push to nDelius" do
        expect(HmppsApi::CommunityApi).not_to receive(:set_handover_dates)
        subject.save!
      end
    end
  end
end
