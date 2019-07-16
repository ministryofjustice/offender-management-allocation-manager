# frozen_string_literal: true

require 'net/imap'
require 'mail'

module Delius
  class Emails
    def self.connect(username, password)
      emails = Emails.new(username, password)

      return emails unless block_given?

      begin
        yield emails
      ensure
        emails.close
      end
    end

    def initialize(username, password)
      @imap = Net::IMAP.new('imap.googlemail.com', 993, true)
      begin
        @imap.login(username, password)
      rescue Net::IMAP::BadResponseError => e
        Rails.logger.error('Failed to log on to IMAP with supplied credentials')
        close
        raise e
      end
    end

    def folder=(folder)
      @imap.examine(folder)
    end

    def latest_attachment
      messages = sorted_mail_messages
      messages.find do |msg|
        attachment = zip_attachment(msg)
        next if attachment.blank?

        break attachment
      end
    end

    def cleanup
      # Mark all but the latest five messages as \Deleted and then
      # force the server to remove them (rather than wait for the
      # deletion when the connection is closed)
      ids = sorted_imap_ids
      old_message_ids = ids - ids.first(5)
      old_message_ids.each { |old_id|
        @imap.store(old_id, '+FLAGS', [:Deleted])
      }
    end

    def connected?
      @imap.disconnected? == false
    end

    def zip_attachment(msg)
      msg.attachments.detect { |a| a.content_type.start_with? 'application/zip' }
    end

    def close
      return if @imap.disconnected?

      @imap.logout
      @imap.disconnect
    end

    def uids
      @imap.search('ALL')
    end

    def sorted_mail_messages
      # Obtain a list of messages in RFC822 format so that they can later
      # be sorted by date.  Unfortunately gmail IMAP claims not to support
      # the 'SORT' instruction.
      messages = @imap.fetch(uids, %w[RFC822]).map { |imap_message|
        Mail.read_from_string imap_message.attr['RFC822']
      }

      messages.sort_by(&:date).reverse
    end

    def sorted_imap_ids
      # Obtain a list of IMAP ids. Unfortunately gmail IMAP claims not to support
      # the 'SORT' instruction.
      @imap.fetch(uids, %w[RFC822]).sort_by { |imap_message|
        mail = Mail.read_from_string imap_message.attr['RFC822']
        mail.date
      }.reverse
    end
  end
end
