# frozen_string_literal: true

MessageContent = Struct.new(:date, :attachments)
AttachmentContent = Struct.new(:content_type)

# This class is intended to be monkey-patched into the default `Mail`
# class. Where the original Mail class can read from a string and populate
# it's attributes, this one uses a hash provided to read_from_string. This
# will have been loaded from a fixture and should have a format like
#  {
#    "date": "21/01/2019",
#    "attachments": [
#      {
#        "content_type": "application/zip"
#      }
#    ]
#  }
#
# Currently no other information is required for the tests.
class MockMailMessage
  def self.read_from_string(hash)
    date = Date.parse(hash['date'])

    attachments = hash['attachments'].map { |att|
      AttachmentContent.new(att['content_type'])
    }

    MessageContent.new(date, attachments)
  end
end
