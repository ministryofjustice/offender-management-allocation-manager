require 'net/imap'
require 'mail'
require 'csv'

class ParoleDataImportService
  IMAP_HOST = 'imap.gmail.com'.freeze
  IMAP_PORT = 993
  EMAIL_FROM = ENV['PPUD_EMAIL_FROM'].freeze
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

  def initialize(log_prefix: 'service=parole_data_import_service', single_day_snapshot: true)
    @log_prefix = log_prefix
    @single_day_snapshot = single_day_snapshot
    @import_id = SecureRandom.uuid
  end

  def import_from_email_with_catchup(date)
    latest_imported_date = ParoleReviewImport.maximum(:snapshot_date)

    if latest_imported_date.nil?
      import_from_email(date)
    elsif latest_imported_date < date
      (latest_imported_date + 1..date).to_a.each { |dt| import_from_email(dt) }
    end

    [@csv_row_import_count, @csv_row_count]
  end

  def import_from_email(date)
    imap = Net::IMAP.new(IMAP_HOST, port: IMAP_PORT, ssl: true)
    fetched_mail = fetch_email(imap, date)

    if fetched_mail.nil?
      Rails.logger.info(format_log('No mail found', date))
    else
      mail = Mail.new(fetched_mail)
      mail.attachments.empty? ? Rails.logger.info(format_log('No attachments found', date)) : process_attachments(mail, date)
    end

    imap.logout
    imap.disconnect

    [@csv_row_import_count, @csv_row_count]
  end

  def import_from_rows(csv_rows, date)
    @csv_row_count = 0
    @csv_row_import_count = 0

    ApplicationRecord.transaction do # To improve performance. The index can cause drag
      csv_rows.each do |csv_row|
        @csv_row_count += 1
        import_row(csv_row, date)
      end
    end

    [@csv_row_import_count, @csv_row_count]
  end

  def self.purge
    ParoleReviewImport.to_purge.delete_all
  end

private

  # It was confirmed by the PPUD team that in the case of duplicate emails, we should take the most recently-received one.
  # For this reason, the email with the highest ID is taken, as the IDs appear to be sequential.
  def fetch_email(imap, date)
    imap.login(ENV['GMAIL_USERNAME'], ENV['GMAIL_PASSWORD'])
    imap.select('INBOX')
    email_id = imap.search(['FROM', EMAIL_FROM, 'SUBJECT', EMAIL_SUBJECT, 'ON', date.strftime('%d-%b-%Y').to_s]).max

    return nil if email_id.nil?

    imap.fetch(email_id, 'RFC822')[0].attr['RFC822']
  end

  def process_attachments(mail, date)
    mail.attachments.each do |attachment|
      if attachment.filename.split('.').last != 'csv'
        Rails.logger.info(format_log("Skipping non-csv attachment '#{attachment.filename}'", date))
        next
      end

      import_from_rows(CSV.new(attachment.body.decoded, headers: true), date)
    end
  end

  def import_row(csv_row, date)
    imported_row = ParoleReviewImport.new

    CSV_HEADINGS.each do |attribute_name, col_heading|
      imported_row.send("#{attribute_name}=", csv_row[col_heading]&.strip)
    end

    imported_row.snapshot_date = date
    imported_row.row_number = @csv_row_count
    imported_row.import_id = @import_id
    imported_row.single_day_snapshot = @single_day_snapshot
    imported_row.save!
    @csv_row_import_count += 1
  rescue StandardError => e
    Rails.logger.error(format_log("CSV row with Review ID: #{csv_row[CSV_HEADINGS[:review_id]]} had error: #{e}", date))
  end

  def format_log(message, date)
    prefix = [
      @log_prefix,
      "snapshot_date=#{date}",
      "import_id=#{@import_id}"
    ].compact.join(',')

    "#{prefix}|#{message}"
  end
end
