RSpec.describe Handover::HandoverCalculation do
  let(:sentence_start_date) { Date.new(2024, 1, 1) }

  describe '::calculate_handover_date' do
    describe 'for determinate case' do
      describe 'when earliest release date is 1 day less than 10 months after sentence start' do
        example 'there is no handover' do
          result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                           earliest_release_date: Date.new(2024, 10, 31),
                                                           is_determinate_parole: false,
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
                                                           is_determinate_parole: false,
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
                                                           is_determinate_parole: false,
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
                                                           is_determinate_parole: false,
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
                                                           is_determinate_parole: false,
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
                                                         is_determinate_parole: false,
                                                         is_indeterminate: true,
                                                         in_open_conditions: true,
                                                         is_early_allocation: false)
        expect(result).to eq [Date.new(2025, 5, 1), :indeterminate_open]
      end

      example 'handover date for non-open prison is 8 months before earliest release date' do
        result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                         earliest_release_date: Date.new(2026, 1, 1),
                                                         is_determinate_parole: false,
                                                         is_indeterminate: true,
                                                         in_open_conditions: false,
                                                         is_early_allocation: false)
        expect(result).to eq [Date.new(2025, 5, 1), :indeterminate]
      end
    end

    describe 'for extended determinate parole case' do
      example 'handover date is 8 months before earliest release date' do
        result = described_class.calculate_handover_date(sentence_start_date: sentence_start_date,
                                                         earliest_release_date: Date.new(2026, 1, 1),
                                                         is_determinate_parole: true,
                                                         is_indeterminate: false,
                                                         in_open_conditions: false,
                                                         is_early_allocation: false)
        expect(result).to eq [Date.new(2025, 5, 1), :determinate_parole]
      end
    end
  end

  describe '::calculate_handover_start_date' do
    describe 'for indeterminate sentences' do
      describe 'when calculated value is before handover date' do
        it 'is date since category was active at open womens prisons' do
          cat_active_since_date = Date.new(2020, 6, 1)
          result = described_class.calculate_handover_start_date(
            handover_date: Date.new(2020, 6, 2),
            category_active_since_date: cat_active_since_date,
            prison_arrival_date: anything,
            is_indeterminate: true,
            open_prison_rules_apply: true,
            in_womens_prison: true,
          )
          expect(result).to eq cat_active_since_date
        end

        it 'is prison arrival date at open mens prisons' do
          prison_arrival_date = Date.new(2020, 6, 1)
          result = described_class.calculate_handover_start_date(
            handover_date: Date.new(2020, 6, 2),
            category_active_since_date: anything,
            prison_arrival_date: prison_arrival_date,
            is_indeterminate: true,
            open_prison_rules_apply: true,
            in_womens_prison: false,
          )
          expect(result).to eq prison_arrival_date
        end
      end

      describe 'when calculated value is after handover date' do
        it 'defaults to handover date at open womens prisons' do
          handover_date = Date.new(2020, 6, 2)
          result = described_class.calculate_handover_start_date(
            handover_date: handover_date,
            category_active_since_date: Date.new(2020, 6, 3),
            prison_arrival_date: anything,
            is_indeterminate: true,
            open_prison_rules_apply: true,
            in_womens_prison: true,
          )
          expect(result).to eq handover_date
        end

        it 'defaults to handover date at open mens prisons' do
          handover_date = Date.new(2020, 6, 2)
          result = described_class.calculate_handover_start_date(
            handover_date: handover_date,
            category_active_since_date: anything,
            prison_arrival_date: Date.new(2020, 6, 3),
            is_indeterminate: true,
            open_prison_rules_apply: true,
            in_womens_prison: false,
          )
          expect(result).to eq handover_date
        end
      end

      describe 'when calculated value is nil' do
        it 'defaults to handover date at open womens prisons' do
          handover_date = Date.new(2020, 6, 2)
          result = described_class.calculate_handover_start_date(
            handover_date: handover_date,
            category_active_since_date: nil,
            prison_arrival_date: anything,
            is_indeterminate: true,
            open_prison_rules_apply: true,
            in_womens_prison: true,
          )
          expect(result).to eq handover_date
        end

        it 'defaults to handover date at open mens prisons' do
          handover_date = Date.new(2020, 6, 2)
          result = described_class.calculate_handover_start_date(
            handover_date: handover_date,
            category_active_since_date: anything,
            prison_arrival_date: nil,
            is_indeterminate: true,
            open_prison_rules_apply: true,
            in_womens_prison: false,
          )
          expect(result).to eq handover_date
        end
      end
    end

    it 'is set to handover date for other cases' do
      handover_date = double :handover_date
      aggregate_failures do
        expect(described_class.calculate_handover_start_date(
                 handover_date: handover_date,
                 category_active_since_date: anything,
                 prison_arrival_date: anything,
                 is_indeterminate: true,
                 open_prison_rules_apply: false,
                 in_womens_prison: false)).to eq handover_date

        expect(described_class.calculate_handover_start_date(
                 handover_date: handover_date,
                 category_active_since_date: anything,
                 prison_arrival_date: anything,
                 is_indeterminate: false,
                 open_prison_rules_apply: true,
                 in_womens_prison: false)).to eq handover_date
      end
    end
  end

  describe '::calculate_responsibility' do
    let(:today) { Date.new(2023, 5, 1) }

    it 'is COM responsible if handover date is not set' do
      expect(described_class.calculate_responsibility(handover_date: nil,
                                                      handover_start_date: Faker::Date.forward,
                                                      today: today))
        .to eq described_class::COM_RESPONSIBLE
    end

    it 'raises an error if handover date is set and handover start date is not set' do
      expect {
        described_class.calculate_responsibility(handover_date: Faker::Date.forward,
                                                 handover_start_date: nil,
                                                 today: today)
      }.to raise_error(described_class::HandoverCalculationArgumentError, /handover_start_date/)
    end

    it 'raises an error if handover start date is after handover date' do
      expect {
        described_class.calculate_responsibility(handover_date: today + 1.day,
                                                 handover_start_date: today + 2.days,
                                                 today: today)
      }.to raise_error(described_class::HandoverCalculationArgumentError, /handover_start_date cannot be after/)
    end

    it 'is COM responsible when handover date is in the past and start date is in the past' do
      expect(described_class.calculate_responsibility(handover_date: today - 1.day,
                                                      handover_start_date: today - 2.days,
                                                      today: today))
        .to eq described_class::COM_RESPONSIBLE
    end

    it 'is COM responsible when handover date is today and start date is in the past' do
      expect(described_class.calculate_responsibility(handover_date: today,
                                                      handover_start_date: today - 1.day,
                                                      today: today))
        .to eq described_class::COM_RESPONSIBLE
    end

    it 'is COM responsible when handover date is today and start date is today' do
      expect(described_class.calculate_responsibility(handover_date: today,
                                                      handover_start_date: today,
                                                      today: today))
        .to eq described_class::COM_RESPONSIBLE
    end

    it 'is POM responsible/COM supporting when handover date is in the future and start date is in the past' do
      expect(described_class.calculate_responsibility(handover_date: today + 1.day,
                                                      handover_start_date: today - 1.day,
                                                      today: today))
        .to eq described_class::POM_RESPONSIBLE_COM_SUPPORTING
    end

    it 'is POM responsible/COM supporting when handover date is in the future and start date is today' do
      expect(described_class.calculate_responsibility(handover_date: today + 1.day,
                                                      handover_start_date: today,
                                                      today: today))
        .to eq described_class::POM_RESPONSIBLE_COM_SUPPORTING
    end

    it 'is POM responsible when handover date is in the future and start date is future' do
      expect(described_class.calculate_responsibility(handover_date: today + 2.days,
                                                      handover_start_date: today + 1.day,
                                                      today: today))
        .to eq described_class::POM_RESPONSIBLE
    end
  end
end
