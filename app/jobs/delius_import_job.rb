require 'delius/emails'
require 'delius/processor'
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
    if decoded_attachment_content.present?
      process_attachment(decoded_attachment_content) do |processor|
        Rails.logger.info('[DELIUS] Processing decrypted file')
        process_decrypted_file(processor)
      end
    end
  end

  def process_decrypted_file(processor)
    update_team_names_and_ldus(processor)
  end

private

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
      # POM-778 Just not covered by tests
      #:nocov:
      Rails.logger.error('[DELIUS] Unable to find an attachment')
      #:nocov:
    end

    Rails.logger.info('[DELIUS] cleaning up inbox')
    emails.cleanup
    Rails.logger.info('[DELIUS] cleaned inbox')
    decoded_attachment_content
  end

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
        # POM-778 Just not covered by tests
        #:nocov:
        lines.each do |line| logger.error(line) end

        raise lines.last
        #:nocov:
      end

      Rails.logger.info('[DELIUS] Attachment decrypted')

      yield Delius::Processor.new(filename)
    end
  end

  def process_record_logging_errors record
    begin
      yield record
    rescue StandardError => e
      Raven.extra_context([:team_code, :team].index_with { |field| record.fetch(field) })
      Raven::capture_exception(e)
    end
  end

  def update_team_names_and_ldus(processor)
    processor.select { |record| active_ldu?(record.fetch(:ldu_code)) }.uniq { |r| r.fetch(:team_code) }.each do |rec|
      process_record_logging_errors(rec) do |record|
        UpdateTeamNameAndLduService.update(
          team_code: record.fetch(:team_code).strip,
          team_name: record.fetch(:team),
          ldu_code: record.fetch(:ldu_code).strip,
          ldu_name: record.fetch(:ldu)
        )
      end
    end

    processor.select { |record| shadow_ldu?(record.fetch(:ldu_code)) }.uniq { |r| r.fetch(:team) }.each do |rec|
      process_record_logging_errors(rec) do |record|
        UpdateShadowTeamAssociationService.update(
          shadow_name: record.fetch(:team),
          shadow_code: record.fetch(:team_code).strip
        )
      end
    end
  end

  def shadow_ldu?(ldu_code)
    ldu_code.match?(/N\d{2}OMIC/)
  end

  def active_ldu?(ldu_code)
    !shadow_ldu?(ldu_code)
  end
end
