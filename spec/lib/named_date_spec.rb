RSpec.describe NamedDate do
  let(:date) { Date.new(2021, 5, 3) }

  describe '==' do
    it 'checks equality by comparing equality of internal attributes' do
      # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
      aggregate_failures do
        # Create new instance of all attributes to ensure we are comparing values and not the objects themselves
        expect(described_class.new(Date.new(2000, 1, 1), 'NAME1') == described_class.new(Date.new(2000, 1, 1), 'NAME1'))
          .to eq true
        expect(described_class.new(Date.new(2000, 1, 1), 'NAME1') == described_class.new(Date.new(2000, 1, 1), 'NAME2'))
          .to eq false
        expect(described_class.new(Date.new(2000, 1, 2), 'NAME1') == described_class.new(Date.new(2000, 1, 1), 'NAME1'))
          .to eq false
      end
      # rubocop:enable Lint/BinaryOperatorWithIdenticalOperands
    end
  end

  describe '::[] constructor' do
    it 'acts as ::new if a date is given' do
      expect(described_class[date, 'NAME1']).to eq described_class.new(date, 'NAME1')
    end
  end

  it 'sorts by date regardless of the name' do
    dates = [
      described_class.new(Date.new(2000, 3, 1), 'A'),
      described_class.new(Date.new(2000, 1, 1), 'B'),
      described_class.new(Date.new(2000, 2, 1), 'C'),
    ]

    expect(dates.sort).to eq [dates[1], dates[2], dates[0]]
  end

  it 'becomes a hash with attributes `name` and `date`' do
    expect(described_class.new(date, 'NAME').to_h).to eq({ 'name' => 'NAME', 'date' => date })
  end
end
