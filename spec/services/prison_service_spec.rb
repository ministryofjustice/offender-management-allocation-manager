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
end
