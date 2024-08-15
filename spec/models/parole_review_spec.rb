require 'rails_helper'

RSpec.describe ParoleReview, type: :model do
  it 'always belongs to an offender' do
    expect(build(:parole_review).offender).not_to be_nil
  end

  describe '#hearing_outcome_as_current' do
    context 'when the hearing outcome is present' do
      it 'returns that outcome' do
        allow(subject).to receive(:hearing_outcome).and_return('Everything OK')
        expect(subject.hearing_outcome_as_current).to eq('Everything OK')
      end
    end

    it 'returns No hearing outcome yet' do
      allow(subject).to receive(:hearing_outcome).and_return(nil)
      expect(subject.hearing_outcome_as_current).to eq('No hearing outcome yet')
    end
  end

  describe '#hearing_outcome_as_historic' do
    context 'when the hearing outcome is present' do
      it 'returns that outcome' do
        allow(subject).to receive(:hearing_outcome).and_return('Everything OK')
        expect(subject.hearing_outcome_as_historic).to eq('Everything OK')
      end
    end

    it 'returns Refused' do
      allow(subject).to receive(:hearing_outcome).and_return(nil)
      expect(subject.hearing_outcome_as_historic).to eq('Refused')
    end
  end

  describe '#formatted_hearing_outcome' do
    it 'correctly reformats the hearing outcome to a UI-friendly state' do
      allow(subject).to receive(:hearing_outcome).and_return('No Parole Board Decision - ABC [*]')
      expect(subject.formatted_hearing_outcome).to eq('No Parole Board decision – ABC')
    end
  end
end
