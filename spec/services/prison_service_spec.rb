require 'rails_helper'

RSpec.describe PrisonService do
  describe '#womens_prison?' do
    subject { described_class::womens_prison?(PrisonService::WOMENS_PRISON_CODES.first) }

    context 'with womens_estate switch on' do
      let(:test_strategy) { Flipflop::FeatureSet.current.test! }

      before do
        test_strategy.switch!(:womens_estate, true)
      end

      after do
        test_strategy.switch!(:womens_estate, false)
      end

      it 'will admit to being a womens prison' do
        expect(subject).to eq(true)
      end
    end

    context 'with womens_estate switch off' do
      it 'will not have any womens prisons' do
        expect(subject).to eq(false)
      end
    end
  end

  it "Get the name of a prison from the code" do
    name = described_class.name_for('LEI')
    expect(name).to eq('HMP Leeds')
  end

  it 'can find all womens prisons' do
    expect(described_class::WOMENS_PRISON_CODES.size).to eq(12)
  end

  it "can return all the prison codes" do
    codes = described_class.prison_codes
    expect(codes.count).to eq(125)
  end

  it "will return nil for an unknown code" do
    name = described_class.name_for('ZZZ')
    expect(name).to be_nil
  end

  it "knows about english prisons" do
    country = described_class.country_for('PVI')
    expect(country).to eq(:england)
  end

  it "knows about welsh prisons" do
    country = described_class.country_for('SWI')
    expect(country).to eq(:wales)
  end

  it "will return prison names from a list in alphabetical order" do
    prisons = described_class.prisons_from_list(%w[NWEB PVI LEI WEI])

    expect(prisons).to be_kind_of(Hash)
    expect(prisons.count).to eq(3)  #  NWEB isn't a prison
    expect(prisons['LEI']).to eq('HMP Leeds')
    expect(prisons).to eq("LEI" => "HMP Leeds", "PVI" => "HMP Pentonville", "WEI" => "HMP Wealstun")
  end
end
