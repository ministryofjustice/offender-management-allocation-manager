require 'rails_helper'
require 'working_day_calculator'

RSpec.describe WorkingDayCalculator do
  # February 2010
  # Su Mo Tu We Th Fr Sa
  #     1  2  3  4  5  6
  #  7  8  9 10 11 12 13
  # 14 15 16 17 18 19 20
  # 21 22 23 24 25 26 27
  # 28

  describe '#working_days_between' do
    subject { described_class.new(holidays).working_days_between(first_date, last_date) }

    context 'with dates within a working week' do
      let(:holidays) { [] }
      let(:first_date) { Date.new(2010, 2, 8) }
      let(:last_date) { Date.new(2010, 2, 12) }

      it 'calculates correct number of days' do
        expect(subject).to eq(4)
      end
    end

    context 'with dates spanning a weekend' do
      let(:holidays) { [] }
      let(:first_date) { Date.new(2010, 2, 5) }
      let(:last_date) { Date.new(2010, 2, 9) }

      it 'calculates correct number of days' do
        expect(subject).to eq(2)
      end
    end

    context 'with dates spaning a weekend and bank holidays' do
      let(:holidays) { [Date.new(2010, 2, 8), Date.new(2010, 2, 9)] }
      let(:first_date) { Date.new(2010, 2, 5) }
      let(:last_date) { Date.new(2010, 2, 12) }

      it 'calculates correct number of days' do
        expect(subject).to eq(3)
      end
    end
  end
end
