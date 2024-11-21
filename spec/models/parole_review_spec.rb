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

    it 'returns nil if the hearing outcome is nil' do
      allow(subject).to receive(:hearing_outcome).and_return(nil)
      expect(subject.formatted_hearing_outcome).to be_nil
    end

    it 'returns nil if the hearing outcome is empty' do
      allow(subject).to receive(:hearing_outcome).and_return('')
      expect(subject.formatted_hearing_outcome).to be_nil
    end
  end

  describe '.for_sentences_starting' do
    describe 'it returns a parole review' do
      specify 'when the THD is the same as or after the provided sentence start date' do
        _parole_review_1 = create(:parole_review, target_hearing_date: Date.parse("01/01/2024"))
        parole_review_2 = create(:parole_review, target_hearing_date: Date.parse("01/01/2025"))
        parole_review_3 = create(:parole_review, target_hearing_date: Date.parse("01/01/2026"))

        expect(described_class.for_sentences_starting(Date.parse("01/01/2025"))).to match_array([parole_review_2, parole_review_3])
      end
    end
  end

  describe '.current' do
    describe 'it returns parole reviews' do
      specify 'that have a hearing_outcome_received_on later than 14 days ago' do
        _parole_review_1 = create(:parole_review, review_status: "Not Active", hearing_outcome_received_on: 15.days.ago)
        parole_review_2 = create(:parole_review, review_status: "Not Active", hearing_outcome_received_on: 13.days.ago)
        parole_review_3 = create(:parole_review, review_status: "Not Active",  hearing_outcome_received_on: 1.week.from_now)

        expect(described_class.current).to match_array([parole_review_2, parole_review_3])
      end

      specify 'with no hearing outcome and the review status is active' do
        parole_review_1 = create(:parole_review, hearing_outcome: 'Not Applicable', review_status: 'Active - Future')
        parole_review_2 = create(:parole_review, hearing_outcome: nil, review_status: 'Active')
        _parole_review_3 = create(:parole_review, hearing_outcome: 'Not Applicable', review_status: "Not Active")

        expect(described_class.current).to match_array([parole_review_1, parole_review_2])
      end
    end
  end

  describe '.previous' do
    describe 'it returns parole reviews' do
      specify 'that have a hearing_outcome_received_on earlier than 14 days ago' do
        parole_review_1 = create(:parole_review, review_status: "Not Active", hearing_outcome_received_on: 15.days.ago)
        _parole_review_2 = create(:parole_review, review_status: "Not Active", hearing_outcome_received_on: 13.days.ago)
        _parole_review_3 = create(:parole_review, review_status: "Not Active",  hearing_outcome_received_on: 1.week.from_now)

        expect(described_class.previous).to match_array([parole_review_1])
      end

      specify 'that have no hearing outcome and are not active' do
        _parole_review_1 = create(:parole_review, hearing_outcome: 'Not Applicable', review_status: 'Active - Future')
        _parole_review_2 = create(:parole_review, hearing_outcome: nil, review_status: 'Active')
        parole_review_3 = create(:parole_review, hearing_outcome: 'Not Applicable', review_status: "Not Active")

        expect(described_class.previous).to match_array([parole_review_3])
      end
    end
  end

  describe 'validations on manual update' do
    it 'validates that the hearing_outcome_received_on is in the past' do
      subject.hearing_outcome_received_on = 1.week.from_now
      subject.valid?(:manual_update)
      expect(subject.errors[:hearing_outcome_received_on]).to include(
        'The date the hearing outcome was confirmed must be in the past'
      )
    end

    it 'validates that the hearing_outcome_received_on is present' do
      subject.hearing_outcome_received_on = nil
      subject.valid?(:manual_update)
      expect(subject.errors[:hearing_outcome_received_on]).to include(
        'The date the hearing outcome was confirmed must be entered and a valid date'
      )
    end
  end
end
