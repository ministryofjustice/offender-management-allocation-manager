# frozen_string_literal: true

require 'net/imap'
require 'mail'

module Delius
  class Emails
    def self.connect(username, password, folder)
      emails = Emails.new(username, password, folder)

      return emails unless block_given?

      begin
        yield emails
      ensure
        emails.close
      end
    end

    def initialize(username, password, folder)
      @imap = Net::IMAP.new('imap.googlemail.com', 993, true)
      begin
        @imap.login(username, password)
        @imap.examine(folder)
      rescue Net::IMAP::BadResponseError => e
        Rails.logger.error('Failed to log on to IMAP with supplied credentials')
        close
        raise e
      end
    end

    def latest_attachment
      sorted_mail_messages.detect do |msg|
        attachment = zip_attachment(msg)
        next if attachment.blank?

        break attachment
      end
    end

    def cleanup
      # In GMail, you have to move things to the Bin folder rather than delete them
      old_uids.each do |old_id|
        @imap.move(old_id, '[Gmail]/Bin')
      end
    end

    def connected?
      @imap.disconnected? == false
    end

    def zip_attachment(msg)
      msg.attachments.detect { |a|
        a.content_type.start_with?('application/zip', 'application/x-zip-compressed')
      }
    end

    def close
      return if @imap.disconnected?

      @imap.logout
      @imap.disconnect
    end

    def recent_uids
      @imap.search(['SINCE', last_week])
    end

    def old_uids
      @imap.search(['BEFORE', last_week])
    end

    def sorted_mail_messages
      # Obtain a list of messages in RFC822 format so that they can later
      # be sorted by date.  Unfortunately gmail IMAP claims not to support
      # the 'SORT' instruction.
      messages = @imap.fetch(recent_uids, %w[RFC822]).map { |imap_message|
        Mail.read_from_string imap_message.attr['RFC822']
      }

      messages.sort_by(&:date).reverse
    end

  private

    # IMAP requires dates in the form dd-MON-yyyy e.g 4-Dec-2019
    def last_week
      (Time.zone.today - 7.days).strftime('%d-%b-%Y')
    end
  end
end
