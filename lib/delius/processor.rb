# frozen_string_literal: true

require 'nokogiri'
require_relative 'sheet'
require_relative 'string_collector'

module Delius
  class Processor
    # Given an XLSX file, this class is responsible for converting the data
    # found in sheet one, into a stream of rows. These rows will contain
    # the textual information from the original spreadsheet. XLSX files
    # are zipped collections of XML documents but the sheet files do not
    # contain data, they contain indexes into a shared string document.
    # As a result, just parsing sheet1.xml will only return those indices
    # so we also need to parse the sharedString.xml file to find the
    # actual data.
    #
    # By parsing the sharedStrings.xml into an ordered list (load_lookup)
    # we then have a mechanism to convert the indices found in sheet1.xml
    # into actual data (process_rows).

    def initialize(file)
      @file = file
      @lookup_table = {}
    end

    def run(&block)
      # The &block passed to this function is used to report back to
      # the caller every time we have a row of data to give them.
      zip_file = Zip::File.open(@file)

      load_lookup(zip_file)
      process_rows(zip_file, &block)
    end

  private

    def load_lookup(zip_file)
      shared_strings = zip_file.entries.filter { |entry|
        entry.name == 'xl/sharedStrings.xml'
      }.first

      count = 0
      collector = Delius::StringCollector.new { |str|
        @lookup_table[count] = str.dup.strip
        count += 1
      }

      parser = Nokogiri::XML::SAX::Parser.new(collector)
      parser.parse(shared_strings.get_input_stream)
    end

    def process_rows(zip_file)
      worksheet = zip_file.entries.filter { |entry|
        entry.name == 'xl/worksheets/sheet1.xml'
      }.first

      doc = Delius::Sheet.new { |row|
        new_row = row.map { |i| @lookup_table[i] }
        yield(new_row)
      }

      parser = Nokogiri::XML::SAX::Parser.new(doc)
      parser.parse(worksheet.get_input_stream)
    end
  end
end
