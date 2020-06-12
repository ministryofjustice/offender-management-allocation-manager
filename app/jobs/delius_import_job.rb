require 'delius/emails'
require 'delius/extract_file_reader'
require 'open3'
require 'zip'

class DeliusImportJob < ApplicationJob
  queue_as :default

  def perform
    ActiveRecord::Base.connection.disable_query_cache!

    username = ENV['DELIUS_EMAIL_USERNAME']
    password = ENV['DELIUS_EMAIL_PASSWORD']
    folder = ENV['DELIUS_EMAIL_FOLDER']

    Rails.logger.info("[DELIUS] Set IMAP folder to #{folder}")

    decoded_attachment_content = nil
    Delius::Emails.connect(username, password, folder) do |emails|
      decoded_attachment_content = process_emails(emails)
    end
    process_attachment(decoded_attachment_content) if decoded_attachment_content.present?
  end

  def process_emails(emails)
    decoded_attachment_content = nil
    Rails.logger.info('[DELIUS] Fetching latest email attachment')
    attachment = emails.latest_attachment

    if attachment.present?
      # At this point attachment.body is the base64 encoded attachment
      # and so we want to store the un-encoded version ready for
      # processing. We want to store the bytes rather than attempt
      # to either convert to string or allow ruby to convert to
      # string in case there are invalid UTF-8 markers in the bytearray
      decoded_attachment_content = attachment.body.decoded.bytes
      Rails.logger.info('[DELIUS] Attachment retrieved')
    else
      Rails.logger.error('[DELIUS] Unable to find an attachment')
    end

    Rails.logger.info('[DELIUS] cleaning up inbox')
    emails.cleanup
    Rails.logger.info('[DELIUS] cleaned inbox')
    decoded_attachment_content
  end

private

  def process_attachment(attachment_bytes)
    # This method is passed the contents of the attachment as a bytearray
    # once it has been base64 decoded which it will then write to a file (in
    # binary format) before processing further.

    Rails.logger.info('[DELIUS] Processing attachment')

    Dir.mktmpdir do |directory|
      # Given the attachment as a bytearray, write it to a local file for
      # processing.
      zipfile = File.join(directory, 'encrypted.zip')
      File.open(zipfile, 'wb') do |file|
        file.write(attachment_bytes.pack('C*'))
      end

      # Unzip the provided file so that we can process the contents. This
      # should contain a single encrypted XLSX file.
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

  def process_decrypted_file(filename)
    Rails.logger.info('[DELIUS] Processing decrypted file')
    reader = Delius::ExtractFileReader.new(filename)
    update_team_names_and_ldus(reader)
    update_shadow_team_associations(reader)
    upsert_delius_data_records(reader)
  end

  def update_shadow_team_associations(reader)
    reader.each do |record|
      next unless shadow_ldu?(record[:ldu_code])

      UpdateShadowTeamAssociationService.update(
        shadow_code: record[:team_code],
        shadow_name: record[:team]
      )
    end
  end

  def update_team_names_and_ldus(reader)
    reader.each do |record|
      next unless active_ldu?(record[:ldu_code])

      UpdateTeamNameAndLduService.update(
        team_code: record[:team_code],
        team_name: record[:team],
        ldu_code: record[:ldu_code]
      )
    end
  end

  def upsert_delius_data_records(reader)
    total = 0

    reader.each do |record|
      if record[:noms_no].present?
        DeliusDataService.upsert(record)
        total += 1
      end
    end

    Rails.logger.info("[DELIUS] #{total} records attempted upsert")
  end

  def shadow_ldu?(ldu_code)
    ldu_code.match?(/N\d{2}OMIC/)
  end

  def active_ldu?(ldu_code)
    !shadow_ldu?(ldu_code)
  end
end
