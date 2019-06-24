require 'rails_helper'
require 'delius/string_collector'

describe Delius::StringCollector do
  it 'parses an xlsx to get the shared strings' do
    filename = 'spec/fixtures/delius/delius_sample.xlsx'

    zip_file = Zip::File.open(filename)
    shared_strings = zip_file.entries.filter { |entry|
      entry.name == 'xl/sharedStrings.xml'
    }.first

    count = 0
    collector = described_class.new { |_str|
      count += 1
    }

    parser = Nokogiri::XML::SAX::Parser.new(collector)
    parser.parse(shared_strings.get_input_stream)

    expect(count).to eq(143)
  end
end
