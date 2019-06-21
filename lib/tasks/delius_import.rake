# frozen_string_literal: true

require 'nokogiri'
require_relative '../../lib/delius/processor'

namespace :delius_import do
  desc 'Loads delius information from a spreadsheet into the DB'
  task :load, [:file] => [:environment] do |_task, args|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    Rails.logger.error('No file specified') if args[:file].blank?
    next if args[:file].blank?

    processor = Delius::Processor.new(args[:file])
    processor.run { |row|
    }
  end
end
