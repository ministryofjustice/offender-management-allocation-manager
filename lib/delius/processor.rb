# frozen_string_literal: true

require 'nokogiri'
require 'zip'
require_relative 'parser'
require_relative 'string_collector'

module Delius
  class Processor
    def initialize(file)
      @file = file
      @lookup_table = {}
    end

    def run(&block)
      zip_file = Zip::File.open(@file)
      load_lookup(zip_file)

      doc = Delius::Parser.new { |row| process_single_row(row, &block) }
      parser = Nokogiri::XML::SAX::Parser.new(doc)

      worksheet = zip_file.entries.filter { |entry|
        entry.name == 'xl/worksheets/sheet1.xml'
      }.first

      parser.parse(worksheet.get_input_stream)
    end

    def process_single_row(row)
      new_row = row.map { |i| @lookup_table[i] }
      yield(new_row)
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
  end
end
