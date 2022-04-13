require 'rails_helper'

RSpec.describe TargetHearingDateForm, type: :model do
  describe 'validation rules' do
    context 'when the date is missing' do
      it { is_expected.to validate_presence_of(:target_hearing_date).with_message('Enter a new target hearing date') }
    end

    context 'when the date is in the past' do
      subject { described_class.new(target_hearing_date: 2.days.ago) }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:target_hearing_date]).to eq ['The new target hearing date must be in the future']
      end
    end

    context 'when the date is today or in the future' do
      let(:future_dates) do
        [
          Time.zone.today,
          Time.zone.tomorrow,
          Time.zone.today + 1.year
        ]
      end

      it { is_expected.to allow_values(*future_dates).for(:target_hearing_date) }
    end
  end
end
