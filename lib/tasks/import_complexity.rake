# frozen_string_literal: true

require 'rake'
require 'complexity_importer'

namespace :complexity do
  desc 'import complexity records from CSV file'
  task :import, [:filename] => [:environment] do |_task, args|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    if args[:filename].blank?
      Rails.logger.error('No CSV file specified') if args[:filename].blank?
    else
      File.open args[:filename] do |f|
        ComplexityImporter.import f
      end
    end
  end
end
