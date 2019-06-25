# frozen_string_literal: true

require 'nokogiri'

module Delius
  class Sheet < Nokogiri::XML::SAX::Document
    DATA_CELL = 'v'
    ROW = 'row'

    def initialize(&block)
      @handler = block
      @current_row = []
      @in_value = false
    end

    def start_element(name, _attrs = [])
      @in_value = name == DATA_CELL
    end

    def characters(str)
      @current_row << str if @in_value
    end

    def end_element(name)
      return unless name == ROW

      row = @current_row.map { |cell|
        cell.dup.strip.to_i
      }
      @current_row = []

      @handler.call(row)
    end
  end
end
