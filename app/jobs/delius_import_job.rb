require 'delius/emails'
require 'delius/processor'
require 'open3'
require 'zip'

class DeliusImportJob < ApplicationJob
  queue_as :default

  FIELDS = [
      :crn, :pnc_no, :noms_no, :fullname, :tier, :roh_cds,
      :offender_manager, :org_private_ind, :org,
      :provider, :provider_code,
      :ldu, :ldu_code,
      :team, :team_code,
      :mappa, :mappa_levels, :date_of_birth
    ].freeze

  def perform
    ActiveRecord::Base.connection.disable_query_cache!
    Rails.logger = Logger.new(STDOUT)

    username = ENV['DELIUS_EMAIL_USERNAME']
    password = ENV['DELIUS_EMAIL_PASSWORD']
    folder = ENV['DELIUS_EMAIL_FOLDER']

    Rails.logger.info('[DELIUS] Retrieving most recent email')

    Delius::Emails.connect(username, password) { |emails|
      Rails.logger.info("[DELIUS] Set IMAP folder to #{folder}")
      emails.folder = folder

      Rails.logger.info('[DELIUS] Fetching latest email attachment')
      attachment = emails.latest_attachment
      Rails.logger.info('[DELIUS] Attachment retrieved')

      if attachment.present?
        process_attachment(attachment.body.decoded)
      else
        Rails.logger.error('[DELIUS] Unable to find an attachment')
      end
    }
  end

private

  # rubocop:disable Metrics/MethodLength
  def process_attachment(contents)
    Rails.logger.info('[DELIUS] Processing attachment')

    Dir.mktmpdir do |directory|
      # Unzip the provided file so that we can process the contents. This
      # should contain a single encrypted XLSX file.
      zipfile = File.join(directory, 'encrypted.zip')
      File.open(zipfile, 'wb') do |file|
        file.write(contents)
      end
      zipcontents = Zip::File.open(zipfile).entries.first.get_input_stream
      encrypted_xlsx = File.join(directory, 'decrypted_attachment')
      File.open(encrypted_xlsx, 'wb') do |file|
        file.write(zipcontents.read)
      end

      Rails.logger.info('[DELIUS] Attachment unzipped')

      # Use msoffice-crypt to decrypt the attachment so that we have a plain
      # unencrypted XLSX file to process.
      filename = File.join(directory, 'decrypted_attachment')
      password = ENV['DELIUS_XLSX_PASSWORD']
      std_output, _status = Open3.capture2(
        'msoffice-crypt', '-d', '-p', password, encrypted_xlsx, filename
      )
      lines = std_output.split("\n")
      if lines.count > 1
        lines.each do |line| logger.error(line) end

        raise lines.last
      end

      Rails.logger.info('[DELIUS] Attachment decrypted')

      process_decrypted_file(filename)
    end
  end
  # rubocop:enable Metrics/MethodLength

  def process_decrypted_file(filename)
    Rails.logger.info('[DELIUS] Processing decrypted file')

    total = 0
    processor = Delius::Processor.new(filename)
    processor.each_with_index do |row, index|
      # skip header row in row[0]
      next if index == 0

      record = {}

      # For each row, map the column to the appropriate column name
      # as the existing column names are not very hash/symbol friendly
      row.each_with_index do |val, idx|
        key = FIELDS[idx]
        record[key] = val
      end

      if record[:noms_no].present?
        DeliusDataService.upsert(record)
        total += 1
      end
    end

    Rails.logger.info("[DELIUS] #{total} records attempted upsert")
  end
end
