# frozen_string_literal: true

namespace :import do
  desc 'Loads email address into the LocalDeliveryUnit table'
  task :ldu, [:filename] => [:environment] do |_task, args|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    if args[:filename].blank?
      Rails.logger.error('No file specified')
    else
      CSV.read(args[:filename], headers: true).each do |row|
        code = row.fetch('LDU code')
        ldu = LocalDeliveryUnit.find_by code: code
        country = row.fetch('Division').strip == 'Wales' ? 'Wales' : 'England'
        Rails.logger.info("Row #{row.inspect}")
        if ldu
          ldu.update!(email_address: row.fetch('Email address'), name: row.fetch('Local delivery unit'), country: country)
        else
          LocalDeliveryUnit.create!(code: code, email_address: row.fetch('Email address'), name: row.fetch('Local delivery unit'), country: country, enabled: false)
        end
      end
    end
  end
end
