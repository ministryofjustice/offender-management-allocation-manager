# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PomOnboardingForm, type: :model do
  subject { described_class.new(schedule_type:, working_pattern:) }

  let(:schedule_type) { nil }
  let(:working_pattern) { nil }

  describe 'validations' do
    context 'when validating search_query' do
      it { is_expected.to validate_length_of(:search_query).is_at_least(3).on(:search) }

      context 'when squishing spaces' do
        subject { described_class.new(search_query: query) }

        context 'when search_query has leading/trailing spaces' do
          let(:query) { '  John Smith  ' }

          it 'removes the spaces' do
            expect(subject.search_query).to eq('John Smith')
          end
        end

        context 'when search_query has multiple spaces between words' do
          let(:query) { 'John    Smith' }

          it 'collapses multiple spaces into one' do
            expect(subject.search_query).to eq('John Smith')
          end
        end

        context 'when search_query is nil' do
          let(:query) { nil }

          it 'returns nil' do
            expect(subject.search_query).to be_nil
          end
        end
      end
    end

    context 'when validating position' do
      it { is_expected.to validate_inclusion_of(:position).in_array(described_class::POM_POSITIONS).on(:position) }
    end

    context 'when validating working pattern' do
      it { is_expected.to validate_inclusion_of(:schedule_type).in_array(described_class::SCHEDULE_TYPES).on(:working_pattern) }

      context 'when part time' do
        let(:schedule_type) { described_class::PART_TIME }

        context 'when working_pattern is 0' do
          let(:working_pattern) { 0 }

          it { is_expected.not_to be_valid(:working_pattern) }
        end

        context 'when working_pattern is not between 1 and 9' do
          let(:working_pattern) { 10 }

          it { is_expected.not_to be_valid(:working_pattern) }
        end

        context 'when working_pattern is not a number' do
          let(:working_pattern) { 'abc' }

          it { is_expected.not_to be_valid(:working_pattern) }
        end

        context 'when working_pattern is valid' do
          let(:working_pattern) { 3 }

          it { is_expected.to be_valid(:working_pattern) }
        end
      end
    end
  end

  describe '#working_pattern=' do
    context 'when full time' do
      let(:schedule_type) { described_class::FULL_TIME }

      it 'resets the working pattern' do
        subject.working_pattern = 5
        expect(subject.working_pattern).to be_nil
      end
    end

    context 'when part time' do
      let(:schedule_type) { described_class::PART_TIME }

      it 'sets the working pattern' do
        subject.working_pattern = 5
        expect(subject.working_pattern).to eq(5)
      end
    end
  end

  describe '#fractional_working_pattern' do
    context 'when full time' do
      let(:schedule_type) { described_class::FULL_TIME }

      it 'returns 1.0' do
        expect(subject.working_pattern_ratio).to eq(1.0)
      end
    end

    context 'when part time' do
      let(:schedule_type) { described_class::PART_TIME }
      let(:working_pattern) { 5 }

      it 'returns the decimal equivalent' do
        expect(subject.working_pattern_ratio).to eq(0.5)
      end
    end
  end

  describe '#hours_per_week_working_pattern' do
    context 'when full time' do
      let(:schedule_type) { described_class::FULL_TIME }

      it 'returns full time hours' do
        expect(subject.hours_per_week).to eq(PomDetail::FULL_TIME_HOURS_PER_WEEK)
      end
    end

    context 'when part time' do
      let(:schedule_type) { described_class::PART_TIME }
      let(:working_pattern) { 5 }

      it 'returns pro-rated hours' do
        expect(subject.hours_per_week).to eq(18.75)
      end
    end
  end
end
