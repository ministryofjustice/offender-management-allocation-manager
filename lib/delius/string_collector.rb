# frozen_string_literal: true

require 'nokogiri'

module Delius
  class StringCollector < Nokogiri::XML::SAX::Document
    DATA_CELL = 't'

    def initialize(&block)
      @inside_cell = false
      @block = block
      @str = ''
    end

    def start_element(name, _attrs)
      @inside_cell = true if name == DATA_CELL
    end

    def characters(str)
      @str += str if @inside_cell
    end

    def end_element(_name)
      @block.call(@str) if @inside_cell
      @str = ''
      @inside_cell = false
    end
  end
end
