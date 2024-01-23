require 'net/imap'
require 'mail'
require 'csv'

class ParoleDataImportJob < ApplicationJob
  queue_as :default

  IMAP_HOST = 'imap.gmail.com'.freeze
  IMAP_PORT = 993
  EMAIL_FROM = 'moic-data@digital.justice.gov.uk'.freeze
  EMAIL_SUBJECT = 'POM Cases list'.freeze

  CSV_HEADINGS = {
    title: 'TITLE',
    nomis_id: 'NOMIS ID',
    prison_no: 'Offender Prison Number',
    sentence_type: 'Sentence Type',
    sentence_date: 'Date Of Sentence',
    tariff_exp: 'Tariff Expiry Date',
    review_date: 'Review Date',
    review_id: 'Review ID',
    review_milestone_date_id: 'Review Milestone Date ID',
    review_type: 'Review Type',
    review_status: 'Review Status',
    curr_target_date: 'Current Target Date (Review)',
    ms13_target_date: 'MS 13 Target Date',
    ms13_completion_date: 'MS 13 Completion Date',
    final_result: 'Final Result (Review)'
  }.freeze

  def perform(date)
    @csv_row_count = 0
    @csv_row_import_count = 0
    @date = date
    @import_id = SecureRandom.uuid
    Rails.logger.info(format_log('Starting'))

    imap = Net::IMAP.new(IMAP_HOST, IMAP_PORT, true)
    fetched_mail = fetch_email(imap)

    if fetched_mail.nil?
      Rails.logger.info(format_log('No mail found'))
    else
      mail = Mail.new(fetched_mail)
      mail.attachments.empty? ? Rails.logger.info(format_log('No attachments found')) : process_attachments(mail)
    end

    imap.logout
    imap.disconnect
    Rails.logger.info(format_log("Complete. #{@csv_row_import_count}/#{@csv_row_count} rows imported"))
  end

private

  # It was confirmed by the PPUD team that in the case of duplicate emails, we should take the most recently-received one.
  # For this reason, the email with the highest ID is taken, as the IDs appear to be sequential.
  def fetch_email(imap)
    imap.login(ENV['GMAIL_USERNAME'], ENV['GMAIL_PASSWORD'])
    imap.select('INBOX')
    email_id = imap.search(['FROM', EMAIL_FROM, 'SUBJECT', EMAIL_SUBJECT, 'ON', @date.strftime('%d-%b-%Y').to_s]).max

    return nil if email_id.nil?

    imap.fetch(email_id, 'RFC822')[0].attr['RFC822']
  end

  def process_attachments(mail)
    mail.attachments.each do |attachment|
      if attachment.filename.split('.').last != 'csv'
        Rails.logger.info(format_log("Skipping non-csv attachment '#{attachment.filename}'"))
        next
      end

      csv_rows = CSV.new(attachment.body.decoded, headers: true)

      csv_rows.each do |csv_row|
        @csv_row_count += 1
        import_row(csv_row)
      end
    end
  end

  def import_row(csv_row)
    imported_row = RawParoleImport.new

    CSV_HEADINGS.each do |attribute_name, col_heading|
      imported_row.send("#{attribute_name}=", csv_row[col_heading].strip)
    end

    imported_row.for_date = @date
    imported_row.import_id = @import_id
    imported_row.save!
    @csv_row_import_count += 1
  rescue StandardError => e
    Rails.logger.error(format_log("CSV row with Review ID: #{csv_row[CSV_HEADINGS[:review_id]]} had error: #{e}"))
  end

  def format_log(message)
    "job=parole_data_import_job,for_date=#{@date},import_id=#{@import_id}|#{message}"
  end
end
