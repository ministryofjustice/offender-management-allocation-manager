# frozen_string_literal: true

MessageContent = Struct.new(:date, :attachments)

class AttachmentContent
  attr_reader :content_type

  Body = Struct.new(:decoded)

  def initialize(att)
    @content_type = att['content_type']
    @body = att['body']
  end

  def body
    file = Rails.root.join('spec', 'fixtures', 'imap', ENV['DELIUS_EMAIL_FOLDER'], @body)

    Body.new File.read(file)
  end
end

# This class is intended to be monkey-patched into the default `Mail`
# class. Where the original Mail class can read from a string and populate
# it's attributes, this one uses a hash provided to read_from_string. This
# will have been loaded from a fixture and should have a format like
#  {
#    "date": "21/01/2019",
#    "attachments": [
#      {
#        "content_type": "application/zip"
#        "body" : <filename>
#      }
#    ]
#  }
#
# Currently no other information is required for the tests.
class MockMailMessage
  def self.read_from_string(hash)
    date = Date.parse(hash['date'])

    attachments = hash['attachments'].map { |att|
      AttachmentContent.new(att)
    }

    MessageContent.new(date, attachments)
  end
end
