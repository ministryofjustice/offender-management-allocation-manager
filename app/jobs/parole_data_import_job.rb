require 'net/imap'
require 'mail'
require 'csv'

class ParoleDataImportJob < ApplicationJob
  queue_as :default

  def perform(date)
    @date = date
    imap = Net::IMAP.new('imap.gmail.com', 993, true)
    mail = Mail.new(fetch_email(imap))
    mail.attachments.empty? ? Rails.logger.info('No attachments found') : process_attachments(mail)
    imap.logout
    imap.disconnect
  end

private

  # It was confirmed by the PPUD team that in the case of duplicate emails, we should take the most recently-received one.
  # For this reason, the email with the highest ID is taken, as the IDs appear to be sequential.
  def fetch_email(imap)
    imap.login(ENV['PAROLE_DATA_IMPORT_EMAIL_USERNAME'], ENV['PAROLE_DATA_IMPORT_EMAIL_PASSWORD'])
    imap.select('INBOX')
    email_id = imap.search(['FROM', 'moic-data@digital.justice.gov.uk', 'SUBJECT', 'POM Cases list', 'ON', @date.strftime('%d-%b-%Y').to_s]).max
    imap.fetch(email_id, 'RFC822')[0].attr['RFC822']
  end

  def process_attachments(mail)
    mail.attachments.each do |attachment|
      if attachment.filename.split('.').last != 'csv'
        Rails.logger.info("Skipping non-csv attachment '#{attachment.filename}'")
        next
      end

      CSV.new(attachment.body.decoded, headers: true).each do |row|
        build_parole_record(row)
      end
    end
  end

  def build_parole_record(csv_record)
    return if csv_record['Review ID'].blank? || csv_record['NOMIS ID'].blank?

    begin
      record = ParoleRecord.create_or_find_by!(review_id: csv_record['Review ID'], nomis_offender_id: csv_record['NOMIS ID'])
      hearing_outcome_received = if record.hearing_outcome_received.present?
                                   record.hearing_outcome_received
                                 elsif record.no_hearing_outcome? && csv_record['Final Result (Review)'] != 'Not Applicable' && csv_record['Final Result (Review)'] != 'Not Specified'
                                   @date - 1.day
                                 end
      record.update(
        target_hearing_date: csv_record['Current Target Date (Review)'],
        custody_report_due: csv_record['MS 13 Target Date'],
        review_status: csv_record['Review Status'],
        hearing_outcome_received: hearing_outcome_received,
        hearing_outcome: csv_record['Final Result (Review)']
      )
    rescue StandardError => e
      Rails.logger.error("Review ID: #{csv_record['Review ID']} had error: #{e}")
    end
  end
end
