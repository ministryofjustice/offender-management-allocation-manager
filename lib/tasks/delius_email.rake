# frozen_string_literal: true

require_relative '../../lib/delius/emails'

namespace :delius_etl do
  desc 'Fetches the most recent attachment from email'
  task :fetch_latest_email, [:output_file] => [:environment] do |_task, args|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    Rails.logger.error('No file specified') if args[:output_file].blank?
    next if args[:output_file].blank?

    username = ENV['DELIUS_EMAIL_USERNAME']
    password = ENV['DELIUS_EMAIL_PASSWORD']
    folder = ENV['DELIUS_EMAIL_FOLDER']

    Delius::Emails.connect(username, password) { |emails|
      emails.folder = folder

      attachment = emails.latest_attachment

      if attachment.present?
        File.open(args[:output_file], 'wb') do |file|
          file.write(attachment.body.decoded)
        end
      else
        Rails.logger.error('Unable to find an attachment')
      end

      emails.cleanup
    }
  end
end
