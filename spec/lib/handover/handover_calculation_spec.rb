RSpec.describe Handover::HandoverCalculation do
  let(:sentence_start_date) { Date.new(2024, 1, 1) }

  describe '::calculate_handover_date' do
    describe 'for determinate case' do
      describe 'when earliest release date is 1 day less than 10 months after sentence start' do
        example 'there is no handover' do
          result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                           earliest_release_date: Date.new(2024, 10, 31),
                                                           is_indeterminate: false,
                                                           in_open_conditions: false,
                                                           is_early_allocation: false)
          expect(result).to eq [nil, :determinate_short]
        end
      end

      describe 'when earliest release date is exactly 10 months after sentence start' do
        example 'there is no handover' do
          result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                           earliest_release_date: Date.new(2024, 11, 1),
                                                           is_indeterminate: false,
                                                           in_open_conditions: false,
                                                           is_early_allocation: false)
          expect(result).to eq [nil, :determinate_short]
        end
      end

      describe 'when earliest release date is 10 months and 1 day after sentence start' do
        example 'handover date is 8 months 14 days before earliest release date' do
          result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                           earliest_release_date: Date.new(2024, 11, 2),
                                                           is_indeterminate: false,
                                                           in_open_conditions: false,
                                                           is_early_allocation: false)
          expect(result).to eq [Date.new(2024, 2, 17), :determinate]
        end
      end

      describe 'when earliest release date is 10 months and 2 day after sentence start' do
        example 'handover date is 8 months 14 days before earliest release date' do
          result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                           earliest_release_date: Date.new(2024, 11, 3),
                                                           is_indeterminate: false,
                                                           in_open_conditions: false,
                                                           is_early_allocation: false)
          expect(result).to eq [Date.new(2024, 2, 18), :determinate]
        end
      end

      describe 'when early allocation' do
        example 'handover date is 15 months before earliest release date' do
          result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                           earliest_release_date: Date.new(2026, 1, 1),
                                                           is_indeterminate: false,
                                                           in_open_conditions: false,
                                                           is_early_allocation: true)
          expect(result).to eq [Date.new(2024, 10, 1), :early_allocation]
        end
      end
    end

    describe 'for indeterminate case' do
      example 'handover date for open prison is 8 months before earliest release date' do
        result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                         earliest_release_date: Date.new(2026, 1, 1),
                                                         is_indeterminate: true,
                                                         in_open_conditions: true,
                                                         is_early_allocation: false)
        expect(result).to eq [Date.new(2025, 5, 1), :indeterminate_open]
      end

      example 'handover date for non-open prison is 8 months before earliest release date' do
        result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                         earliest_release_date: Date.new(2026, 1, 1),
                                                         is_indeterminate: true,
                                                         in_open_conditions: false,
                                                         is_early_allocation: false)
        expect(result).to eq [Date.new(2025, 5, 1), :indeterminate]
      end
    end
  end
end
