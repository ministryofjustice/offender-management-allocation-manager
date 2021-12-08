require 'rails_helper'

RSpec.describe PrisonService do
  describe '#womens_prison?' do
    subject { described_class::womens_prison?(PrisonService::WOMENS_PRISON_CODES.first) }

    it 'will admit to being a womens prison' do
      expect(subject).to eq(true)
    end
  end

  it "Get the name of a prison from the code" do
    name = described_class.name_for('LEI')
    expect(name).to eq('Leeds (HMP)')
  end

  it 'can find all womens prisons' do
    expect(described_class::WOMENS_PRISON_CODES.size).to eq(12)
  end

  it "can return all the prison codes" do
    codes = described_class.prison_codes
    expect(codes.count).to eq(121)
  end

  it "will return nil for an unknown code" do
    name = described_class.name_for('ZZZ')
    expect(name).to be_nil
  end
end
