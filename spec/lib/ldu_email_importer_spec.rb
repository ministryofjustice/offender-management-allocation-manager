require 'rails_helper'
require 'ldu_email_importer'
require 'csv'

describe LDUEmailImporter do
  let(:rows) {
    [
    ['LDU Code', 'Email Address'],
    ['A1', 'test@example.com'],
    ['A2', 'test2@example.com'],
    ['A3'],
    ['A4']
  ]
  }

  let(:file_path) { "tmp/emails_test.csv" }

  let!(:csv) do
    CSV.open(file_path, "w") do |csv|
      rows.each do |row|
        csv << row
      end
    end
  end

  after(:each) do File.delete(file_path) end

  it "can update records" do
    create(:local_divisional_unit, code: 'A1', email_address: nil)
    create(:local_divisional_unit, code: 'A2', email_address: 'old_address@example.com')
    create(:local_divisional_unit, code: 'A3', email_address: nil)

    described_class.import(file_path)

    a1 = LocalDivisionalUnit.find_by(code: 'A1')
    expect(a1.email_address).to eq('test@example.com')

    a2 = LocalDivisionalUnit.find_by(code: 'A2')
    expect(a2.email_address).to eq('test2@example.com')

    a3 = LocalDivisionalUnit.find_by(code: 'A3')
    expect(a3.email_address).to be_nil

    a4 = LocalDivisionalUnit.find_by(code: 'A4')
    expect(a4).to be_nil
  end
end
