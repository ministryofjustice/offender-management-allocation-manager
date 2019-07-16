MessageContent = Struct.new(:date, :attachments)
AttachmentContent = Struct.new(:content_type)

class MockMailMessage
  # We are no actually expecting a string here, we'll be passing a hash,
  # which will have been loaded from the fixture data. The alternative is
  # encoding a json object as a string inside the JSON object, or writing
  # RFC822 format text in the JSON.
  def self.read_from_string(hash)
    date = Date.parse(hash['date'])

    attachments = hash['attachments'].map { |att|
      AttachmentContent.new(att['content_type'])
    }

    MessageContent.new(date, attachments)
  end
end
