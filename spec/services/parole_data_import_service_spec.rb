# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParoleDataImportService do
  let(:attachment_1_body) do
    double(
      decoded: "TITLE,NOMIS ID,Offender Prison Number,Sentence Type,Date Of Sentence,Tariff Expiry Date,Review Date,Review ID,Review Milestone Date ID,Review Type,Review Status,Current Target Date (Review),MS 13 Target Date,MS 13 Completion Date,Final Result (Review)
                13 - Prison receive OS report,A1111AA,A12345,Discretionary,01-01-2020,01-01-2022,01-01-2022,123456,12345678,zzzGPP - I,Active - Referred,01-01-2022,01-01-2021,NULL,Not Applicable
                13 - Prison receive OS report,B2222BB,B67890,Discretionary,01-01-2020,01-01-2022,01-01-2019,098765,98765432,zzzGPP - I,Cancelled,01-01-2019,01-01-2019,NULL,Not Applicable"
    )
  end
  let(:attachment_mock_1) { double(filename: 'attachment_mock_1.csv', body: attachment_1_body) }
  let(:attachment_mock_2) { double(filename: 'attachment_mock_2.txt') }

  let(:imap_mock) do
    double(login: true,
           select: true,
           search: ['123', '456'],
           fetch: [double(attr: { 'RFC822' => true })],
           logout: true, disconnect: true)
  end

  before do
    allow(Net::IMAP).to receive(:new).and_return(imap_mock)
    allow(Mail).to receive(:new).and_return(mail_mock)
  end

  context 'when there are attachments on the email' do
    context 'when one attachment is a csv' do
      let(:mail_mock) { double(attachments: [attachment_mock_1]) }

      it 'creates raw parole import records from the csv' do
        allow(Rails.logger).to receive(:info).and_call_original
        subject.import_from_email(Time.zone.today)

        expect(Rails.logger).not_to have_received(:info).with(/skipping non-csv attachment/i)
        expect(ParoleReviewImport.count).to eq(2)
      end
    end

    context 'when there is not a csv attachment' do
      let(:mail_mock) { double(attachments: [attachment_mock_2]) }

      it 'logs info that the file is being skipped' do
        allow(Rails.logger).to receive(:info).and_call_original
        subject.import_from_email(Time.zone.today)

        expect(Rails.logger).to have_received(:info).with(/skipping non-csv attachment/i)
        expect(ParoleReviewImport.count).to eq(0)
      end
    end
  end

  context 'when there are no attachments on the email' do
    let(:mail_mock) { double(attachments: []) }

    it 'logs that no attachments were found' do
      allow(Rails.logger).to receive(:info).and_call_original
      subject.import_from_email(Time.zone.today)

      expect(Rails.logger).to have_received(:info).with(/no attachments found/i)
    end
  end

  context 'when import throws an error' do
    let(:mail_mock) { double(attachments: [attachment_mock_1]) }

    it 'logs the error message' do
      allow(Rails.logger).to receive(:error).and_call_original
      allow_any_instance_of(ParoleReviewImport).to receive(:save!).and_raise(StandardError)

      # Error logged for each row in the CSV that raised an error
      expect { subject.import_from_email(Time.zone.today) }.not_to raise_error
      expect(Rails.logger).to have_received(:error).twice
    end
  end
end
