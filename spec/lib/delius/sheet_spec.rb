require 'rails_helper'
require 'delius/sheet'

describe Delius::Sheet do
  it 'parses an excel spreadsheet get get lookup ids' do
    filename = 'spec/fixtures/delius/delius_sample.xlsx'
    zip_file = Zip::File.open(filename)

    count = 0
    doc = described_class.new { |_row| count += 1 }
    parser = Nokogiri::XML::SAX::Parser.new(doc)

    worksheet = zip_file.entries.filter { |entry|
      entry.name == 'xl/worksheets/sheet1.xml'
    }.first

    parser.parse(worksheet.get_input_stream)

    expect(count).to eq(93)
  end
end
