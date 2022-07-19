# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParoleDataImportJob, type: :job do
  let(:attachment_1_body) do
    double(
      decoded: "TITLE,NOMIS ID,Offender Prison Number,Sentence Type,Date Of Sentence,Tariff Expiry Date,Review Date,Review ID,Review Milestone Date ID,Review Type,Review Status,Current Target Date (Review),MS 13 Target Date,MS 13 Completion Date,Final Result (Review)
                13 - Prison receive OS report,A1111AA,A12345,Discretionary,01-01-2020,01-01-2022,01-01-2022,123456,12345678,zzzGPP - I,Active - Referred,01-01-2022,01-01-2021,NULL,Not Applicable
                13 - Prison receive OS report,B2222BB,B67890,Discretionary,01-01-2020,01-01-2022,01-01-2019,098765,98765432,zzzGPP - I,Active,01-01-2019,01-01-2019,NULL,Not Applicable
                13 - Prison receive OS report,C3333CC,C54321,Discretionary,01-01-2020,01-01-2022,01-01-2019,024680,02468024,zzzGPP - I,Cancelled,01-01-2019,01-01-2019,NULL,Not Specified"
    )
  end
  let(:attachment_mock_1) { double(filename: 'attachment_mock_1.csv', body: attachment_1_body) }
  let(:attachment_mock_2) { double(filename: 'attachment_mock_2.txt') }
  let(:imap_mock) { double(login: true, select: true, search: ['123', '456'], fetch: [double(attr: { RFC822: true })], logout: true, disconnect: true) }

  before do
    allow(Net::IMAP).to receive(:new).and_return(imap_mock)
    allow(Rails.logger).to receive(:info)

    build(:offender, nomis_offender_id: 'A1111AA').save!
    build(:offender, nomis_offender_id: 'B2222BB').save!
    build(:offender, nomis_offender_id: 'C3333CC').save!
  end

  describe 'On record creation' do
    before do
      allow(Mail).to receive(:new).and_return(mail_mock)
    end

    context 'when there are attachments on the email' do
      context 'when one attachment is a csv' do
        let(:mail_mock) { double(attachments: [attachment_mock_1]) }

        it 'creates parole records from the csv' do
          expect(Rails.logger).not_to receive(:info).with(/skipping non-csv attachment/i)

          described_class.perform_now(Time.zone.today)

          parole_application_1 = ParoleRecord.find_by(review_id: '123456', nomis_offender_id: 'A1111AA')
          expect(parole_application_1.active?).to eq(true)
          expect(parole_application_1.current_hearing_outcome).to eq('No hearing outcome yet')

          parole_application_2 = ParoleRecord.find_by(review_id: '098765', nomis_offender_id: 'B2222BB')
          expect(parole_application_2.active?).to eq(true)
          expect(parole_application_2.previous_hearing_outcome).to eq('No hearing outcome given')

          parole_application_3 = ParoleRecord.find_by(review_id: '024680', nomis_offender_id: 'C3333CC')
          expect(parole_application_3.active?).to eq(false)
          expect(parole_application_3.previous_hearing_outcome).to eq('No hearing outcome given')
        end
      end

      context 'when there is not a csv attachment' do
        let(:mail_mock) { double(attachments: [attachment_mock_2]) }

        it 'logs info that the file is being skipped' do
          allow(Rails.logger).to receive(:info)

          expect(Rails.logger).to receive(:info).with(/skipping non-csv attachment/i)
          expect(ParoleRecord).not_to receive(:create_or_find_by!)

          described_class.perform_now(Time.zone.today)
        end
      end
    end

    context 'when there are no attachments on the email' do
      let(:mail_mock) { double(attachments: []) }

      it 'logs that no attachments were found' do
        allow(Rails.logger).to receive(:info)

        expect(subject).not_to receive(:process_attachments)
        expect(Rails.logger).to receive(:info).with(/no attachments found/i)

        described_class.perform_now(Time.zone.today)
      end
    end

    context 'when find_by_or_create! throws an error' do
      let(:mail_mock) { double(attachments: [attachment_mock_1]) }

      it 'logs the error message to the console' do
        allow(ParoleRecord).to receive(:create_or_find_by!).and_raise(StandardError)

        # Error logged for each row in the CSV that raised an error
        expect(Rails.logger).to receive(:error).exactly(3).times

        expect { described_class.perform_now(Time.zone.today) }.not_to raise_error
      end
    end
  end

  describe 'On record update' do
    context 'when updating one of the records' do
      let(:attachment_mock_3) { double(filename: 'attachment_mock_3.csv', body: attachment_3_body) }
      let(:attachment_3_body) do
        double(
          decoded: "TITLE,NOMIS ID,Offender Prison Number,Sentence Type,Date Of Sentence,Tariff Expiry Date,Review Date,Review ID,Review Milestone Date ID,Review Type,Review Status,Current Target Date (Review),MS 13 Target Date,MS 13 Completion Date,Final Result (Review)
                    13 - Prison receive OS report,A1111AA,A12345,Discretionary,01-01-2020,01-01-2022,01-01-2022,123456,12345678,zzzGPP - I,Inactive,01-01-2022,01-01-2021,01-01-2021,Stay In Closed [*]
                    13 - Prison receive OS report,B2222BB,B67890,Discretionary,01-01-2020,01-01-2022,01-01-2019,098765,98765432,zzzGPP - I,Active,01-01-2019,01-01-2019,NULL,Not Applicable
                    13 - Prison receive OS report,C3333CC,C54321,Discretionary,01-01-2020,01-01-2022,01-01-2019,024680,02468024,zzzGPP - I,Cancelled,01-01-2019,01-01-2019,NULL,Not Specified"
        )
      end

      it 'updates the changed record and leaves any others the same' do
        # Seed with initial data
        allow(Mail).to receive(:new).and_return(double(attachments: [attachment_mock_1]))
        described_class.perform_now(Time.zone.today)

        # Ensure data is seeded correctly
        parole_application_1 = ParoleRecord.find_by(review_id: '123456', nomis_offender_id: 'A1111AA')
        expect(parole_application_1.active?).to eq(true)
        expect(parole_application_1.current_hearing_outcome).to eq('No hearing outcome yet')

        # Update seed data with new data
        allow(Mail).to receive(:new).and_return(double(attachments: [attachment_mock_3]))
        described_class.perform_now(Time.zone.today)

        parole_application_1 = ParoleRecord.find_by(review_id: '123456', nomis_offender_id: 'A1111AA')
        expect(parole_application_1.active?).to eq(false)
        expect(parole_application_1.current_hearing_outcome).to eq('Stay in closed')

        parole_application_2 = ParoleRecord.find_by(review_id: '098765', nomis_offender_id: 'B2222BB')
        expect(parole_application_2.active?).to eq(true)
        expect(parole_application_2.previous_hearing_outcome).to eq('No hearing outcome given')

        parole_application_3 = ParoleRecord.find_by(review_id: '024680', nomis_offender_id: 'C3333CC')
        expect(parole_application_3.active?).to eq(false)
        expect(parole_application_3.previous_hearing_outcome).to eq('No hearing outcome given')
      end
    end
  end
end
