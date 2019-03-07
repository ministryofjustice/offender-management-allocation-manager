require 'rails_helper'

RSpec.describe PrisonService do
  it "Get the name of a prison from the code" do
    name = described_class.name_for('LEI')
    expect(name).to eq('HMP Leeds')
  end

  it "will return nil for an unknown code" do
    name = described_class.name_for('ZZZ')
    expect(name).to be_nil
  end

  it "will return prison names from a list" do
    prisons = described_class.prisons_from_list(%w[LEI NWEB PVI WEI])

    expect(prisons).to be_kind_of(Hash)
    expect(prisons.count).to eq(3)  #  NWEB isn't a prison
    expect(prisons['LEI']).to eq('HMP Leeds')
  end
end
