require 'rails_helper'

describe Nomis::OffenderSummary do
  describe '#earliest_release_date' do
    context 'with blank sentence detail' do
      before { subject.sentence = Nomis::SentenceDetail.new }

      it 'responds with no earliest release date' do
        expect(subject.sentence.earliest_release_date).to be_nil
      end
    end

    context 'with sentence detail with dates' do
      before do
        subject.sentence = Nomis::SentenceDetail.new.tap do |sentence|
          sentence.sentence_start_date = Date.new(2005, 2, 3)
          sentence.parole_eligibility_date = parole_eligibility_date
          sentence.conditional_release_date = conditional_release_date
        end
      end

      context 'when comprised of dates in the past and the future' do
        let(:parole_eligibility_date) { Date.new(2009, 1, 1) }
        let(:automatic_release_date) { Time.zone.today }
        let(:conditional_release_date) { Time.zone.today + 3.days }

        it 'will display the earliest of the dates in the future' do
          expect(subject.sentence.earliest_release_date).
              to eq(conditional_release_date)
        end
      end

      context 'with a conditional release date after a parole eligibility date' do
        let(:parole_eligibility_date) { Date.new(2009, 1, 1) }
        let(:conditional_release_date) { Date.new(2009, 1, 10) }

        it 'uses parole eligibility date' do
          expect(subject.sentence.earliest_release_date).
            to eq(parole_eligibility_date)
        end
      end

      context 'with a conditional release date before a parole eligibility date' do
        let(:conditional_release_date) { Date.new(2009, 12, 3) }
        let(:parole_eligibility_date) { Date.new(2009, 12, 28) }

        it 'uses conditional release date' do
          expect(subject.sentence.earliest_release_date).
            to eq(conditional_release_date)
        end
      end
    end
  end

  describe '#sentenced?' do
    context 'with sentence detail with a release date' do
      before do
        subject.sentence = Nomis::SentenceDetail.new.tap do |sentence|
          sentence.sentence_start_date = Date.new(2005, 2, 3)
          sentence.release_date = Time.zone.today
        end
      end

      it 'marks the offender as sentenced' do
        expect(subject.sentenced?).to be true
      end
    end

    context 'with blank sentence detail' do
      before { subject.sentence = Nomis::SentenceDetail.new }

      it 'marks the offender as not sentenced' do
        expect(subject.sentenced?).to be false
      end
    end
  end

  describe '#age' do
    context 'with a date of birth 50 years ago' do
      before { subject.date_of_birth = 50.years.ago }

      it 'returns 50' do
        expect(subject.age).to eq(50)
      end
    end

    context 'with a date of birth just under 50 years ago' do
      before { subject.date_of_birth = 50.years.ago + 1.day }

      it 'returns 49' do
        expect(subject.age).to eq(49)
      end
    end

    context 'with an 18th birthday in a past month' do
      Timecop.travel('19 Feb 2020') do
        before { subject.date_of_birth = '5 Jan 2002'.to_date }

        it 'returns 18' do
          expect(subject.age).to eq(18)
        end
      end
    end

    context 'with no date of birth' do
      before { subject.date_of_birth = nil }

      it 'returns nil' do
        expect(subject.age).to be_nil
      end
    end
  end
end
