require 'rails_helper'
require 'delius/processor.rb'

describe Delius::Processor do
  it 'can extract rows from a spreadsheet one at a time' do
    filename = 'spec/fixtures/delius/delius_sample.xlsx'
    e = described_class.new(filename)

    expect(e.count).to eq(93)
  end
end
