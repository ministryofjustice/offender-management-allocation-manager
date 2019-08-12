require 'rails_helper'
require 'support/lib/mock_imap'
require 'support/lib/mock_mail'

RSpec.describe DeliusImportJob, type: :job do
  before do
    stub_const("Net::IMAP", MockIMAP)
    stub_const("Mail", MockMailMessage)
  end

  it 'doesnt crash' do
    ENV['DELIUS_EMAIL_FOLDER'] = 'delius_import_job'
    ENV['DELIUS_XLSX_PASSWORD'] = 'secret'

    expect {
      described_class.perform_now
    }.to change(DeliusData, :count).by(1)
    expect(DeliusData.last.crn).to eq('crn code')
    expect(DeliusData.last.tier).to eq('A1')
  end
end
