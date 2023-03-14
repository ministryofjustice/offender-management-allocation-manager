RSpec.describe Handover::HandoverCalculation do
  let(:sentence_start_date) { Date.new(2024, 1, 1) }

  describe '::calculate_handover_date' do
    describe 'for determinate case' do
      describe 'when earliest release date is 1 day less than 10 months after sentence start' do
        example 'there is no handover' do
          result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                           earliest_release_date: Date.new(2024, 10, 31),
                                                           is_determinate: true)
          expect(result).to eq [nil, :determinate_short]
        end
      end

      describe 'when earliest release date is exactly 10 months after sentence start' do
        example 'there is no handover' do
          result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                           earliest_release_date: Date.new(2024, 11, 1),
                                                           is_determinate: true)
          expect(result).to eq [nil, :determinate_short]
        end
      end

      describe 'when earliest release date is 10 months and 1 day after sentence start' do
        example 'handover date is 8 months 14 days before earliest release date' do
          result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                           earliest_release_date: Date.new(2024, 11, 2),
                                                           is_determinate: true)
          expect(result).to eq [Date.new(2024, 2, 17), :determinate]
        end
      end

      describe 'when earliest release date is 10 months and 2 day after sentence start' do
        example 'handover date is 8 months 14 days before earliest release date' do
          result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                           earliest_release_date: Date.new(2024, 11, 3),
                                                           is_determinate: true)
          expect(result).to eq [Date.new(2024, 2, 18), :determinate]
        end
      end
    end

    describe 'for indeterminate case' do
      it 'raises an error' do
        expect {
          described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                  earliest_release_date: sentence_start_date + 1.year,
                                                  is_determinate: false)
        }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '::calculate_responsibility' do
    describe 'for determinate case' do
      describe 'when there is no handover date' do
        example 'responsibility is with COM' do
          expect(described_class.calculate_responsibility(handover_date: nil, today: Faker::Date.rand)).to eq :com
        end
      end

      describe 'when handover date is today' do
        example 'responsibility is with COM' do
          expect(described_class.calculate_responsibility(handover_date: Date.new(2024, 6, 12),
                                                          today: Date.new(2024, 6, 12))).to eq :com
        end
      end

      describe 'when handover date was yesterday' do
        example 'responsibility is with COM' do
          expect(described_class.calculate_responsibility(handover_date: Date.new(2024, 6, 11),
                                                          today: Date.new(2024, 6, 12))).to eq :com
        end
      end

      describe 'when handover date is tomorrow' do
        example 'responsibility is with POM' do
          expect(described_class.calculate_responsibility(handover_date: Date.new(2024, 6, 13),
                                                          today: Date.new(2024, 6, 12))).to eq :pom
        end
      end
    end
  end
end
