# frozen_string_literal: true

require 'singleton'
require 'ostruct'

IMAPMessage = Struct.new(:attr)

# The MockIMAP class is a fake implementation of the default Ruby IMAP client.
# It is intended to be used in tests where a real IMAP server is impractical,
# and can be used in rspec by calling `stub_const("Net::IMAP", MockIMAP)`
# before the IMAP client is used.
#
# Currently this class only implements the bare minimum to allow the email
# specs in this project to pass, and does not yet support 'deleting' of
# messages.
#
# Each fixture represents one message in the IMAP folder (where the
# directory name on disk is the mocked IMAP folder).  The name of the
# file should be an integer (the IMAP id) and a .json file.
#
# Fixtures should be in the format below, where RFC822 is required.
#
# {
#   "RFC822": {
#     "date": "21/01/2019",
#     "attachments": [
#       {
#         "content_type": "application/zip"
#       }
#     ]
#   }
# }
#
# To specify the username and password that the client should accept you
# should use the following example at the start of your tests.
#
#   MockIMAP.configure do |config|
#     config.expected_username = 'user'
#     config.expected_password = 'pass'
#   end
#
class MockIMAP
  class BadResponseError < StandardError; end

  class MockIMAPConfig
    include Singleton

    attr_accessor :expected_username, :expected_password
  end

  attr_accessor :connected, :current_folder

  def self.configure
    yield MockIMAPConfig.instance
  end

  def initialize(_server, _port, _ssl); end

  def login(username, password)
    @current_folder = 'INBOX'

    if username != config.expected_username || password != config.expected_password
      @connected = false
      raise Net::IMAP::BadResponseError
    end

    @connected = true
  end

  def logout; end

  # Although the actual examine IMAP command does return folder status, we only use
  # it as a proxy for switching from the current folder (INBOX by default) to a new
  # folder.
  def examine(folder)
    @current_folder = folder
  end

  # The IMAP search command can take complex search terms, however it is only used
  # in our tests with "ALL" which simply returns the imap message ids for all messages
  # in the current folder.
  def search(_term)
    entries = Dir.entries(fixture_path).reject { |f| File.directory? f }
    entries.shuffle.map { |filename|
      File.basename(filename, '.json').to_i
    }
  end

  # Fetch typically returns IMAP message objects for the specified uids, however in
  # this implementation it returns the contents of the JSON fixture which is made
  # available via the :attr accessor in the IMAPMessage struct.
  def fetch(uids, _format)
    uids.map { |uid|
      raw = File.read(File.join(fixture_path, "#{uid}.json"))
      hash = JSON.parse(raw)
      IMAPMessage.new(hash)
    }
  end

  def disconnect
    @connected = false
  end

  def disconnected?
    @connected == false
  end

private

  def config
    MockIMAPConfig.instance
  end

  def fixture_path
    Rails.root.join('spec', 'fixtures', 'imap', @current_folder).to_s
  end
end
