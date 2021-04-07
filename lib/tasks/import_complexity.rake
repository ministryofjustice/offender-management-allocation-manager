# frozen_string_literal: true

require 'rake'
require 'complexity_importer'

namespace :complexity do
  desc 'import complexity records from CSV file'
  task :import, [:filename] => [:environment] do |_task, args|
    Rails.logger = Logger.new(STDOUT)

    if args[:filename].blank?
      Rails.logger.error('No CSV file specified') if args[:filename].blank?
    else
      Rails.logger.info('Beginning import')

      File.open args[:filename] do |f|
        ComplexityImporter.import f
      end

      Rails.logger.info('Import complete')
    end
  end
end
