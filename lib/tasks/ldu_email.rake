# frozen_string_literal: true

require_relative '../ldu_email_importer'

namespace :ldu_email do
  desc 'Loads email address into the local_division_unit table'
  task :import, [:filename] => [:environment] do |_task, args|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    Rails.logger.error('No CSV file specified') if args[:filename].blank?
    next if args[:filename].blank?

    LDUEmailImporter.import(args[:filename])
  end
end
