require 'rails_helper'
require 'delius/emails'
require 'support/lib/mock_imap'
require 'support/lib/mock_mail'

describe Delius::Emails do
  let!(:username) { 'user' }
  let!(:password) { 'pass' }

  before(:each) do
    MockIMAP.configure do |config|
      config.expected_username = 'user'
      config.expected_password = 'pass'
    end
    stub_const("Net::IMAP", MockIMAP)
    stub_const("Mail", MockMailMessage)
  end

  it 'can handle failed login' do
    expect{ described_class.connect('fake', 'incorrect') }.to raise_error(Net::IMAP::BadResponseError)
  end

  it 'can login' do
    described_class.connect(username, password) { |emails|
    }
  end

  it 'can get imap ids for a folder' do
    described_class.connect(username, password) { |emails|
      emails.folder = 'sorted_small'
      ids = emails.uids

      expect(ids.count).to eq(3)
      expect(ids.sort).to eq([1, 2, 3])
    }
  end

  it 'can sort messages in a folder' do
    described_class.connect(username, password) { |emails|
      emails.folder = 'sorted_small'
      messages = emails.sorted_mail_messages

      expect(messages.count).to eq(3)
      expect(messages.map(&:date)).to eq([Date.parse('21/06/2019'), Date.parse('21/1/2019'), Date.parse('10/1/2019')])
    }
  end

  it 'can retrieve an attachment' do
    described_class.connect(username, password) { |emails|
      emails.folder = 'sorted_small'
      attachment = emails.latest_attachment

      expect(attachment).not_to be_nil
    }
  end

  it 'can work with no attachment' do
    described_class.connect(username, password) { |emails|
      emails.folder = 'no_attachments'
      attachment = emails.latest_attachment

      expect(attachment).to be_nil
    }
  end

  it 'can cleanup without crashing' do
    described_class.connect(username, password) { |emails|
      emails.folder = 'sorted_small'
      emails.cleanup
    }
  end

  it 'can check for connected' do
    described_class.connect(username, password) { |emails|
      emails.folder = 'sorted_small'
      expect(emails.connected?).to eq(true)
    }
  end
end
