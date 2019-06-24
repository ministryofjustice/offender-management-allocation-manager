require 'rails_helper'
require 'delius/processor.rb'

describe Delius::Processor do
  it 'can extract rows from a spreadsheet one at a time' do
    filename = 'spec/fixtures/delius/delius_sample.xlsx'
    e = described_class.new(filename)

    count = 0
    e.run do |_row|
      count += 1
    end

    expect(count).to eq(93)
  end
end
