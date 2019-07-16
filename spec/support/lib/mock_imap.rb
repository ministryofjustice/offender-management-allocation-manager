require 'singleton'
require 'ostruct'

IMAPMessage = Struct.new(:attr)

class MockIMAP
  class BadResponseError < StandardError; end

  attr_accessor :connected, :current_folder

  def self.configure
    imap = IMAPConfig.instance
    yield imap
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

  def examine(folder)
    @current_folder = folder
  end

  def search(_term)
    entries = Dir.entries(fixture_path).reject { |f| File.directory? f }
    entries.shuffle.map { |filename|
      File.basename(filename, '.json').to_i
    }
  end

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
    IMAPConfig.instance
  end

  def fixture_path
    Rails.root.join('spec', 'fixtures', 'imap', @current_folder).to_s
  end
end

class IMAPConfig
  include Singleton

  attr_accessor :expected_username, :expected_password
end
