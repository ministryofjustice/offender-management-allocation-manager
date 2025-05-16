# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParoleDataImportService do
  let(:s3_object_csv_content) do
    "TITLE,NOMIS ID,Offender Prison Number,Sentence Type,Date Of Sentence,Tariff Expiry Date,Review Date,Review ID,Review Milestone Date ID,Review Type,Review Status,Current Target Date (Review),MS 13 Target Date,MS 13 Completion Date,Final Result (Review)
    13 - Prison receive OS report,A1111AA,A12345,Discretionary,01-01-2020,01-01-2022,01-01-2022,123456,12345678,zzzGPP - I,Active - Referred,01-01-2022,01-01-2021,NULL,Not Applicable
    13 - Prison receive OS report,B2222BB,B67890,Discretionary,01-01-2020,01-01-2022,01-01-2019,098765,98765432,zzzGPP - I,Cancelled,01-01-2019,01-01-2019,NULL,Not Applicable"
  end

  describe 'S3 bucket import' do
    let(:date) { Date.new(2025, 3, 25) }
    let(:s3_list_mock) { instance_double(S3::List, call: s3_files) }
    let(:s3_read_mock) { instance_double(S3::Read, call: s3_object_csv_content) }

    before do
      allow(S3::List).to receive(:new).and_return(s3_list_mock)
      allow(S3::Read).to receive(:new).and_return(s3_read_mock)
    end

    context 'when there are files in the S3 bucket' do
      let(:s3_files) { [{ object_key: 'PPUD_MPC_20250325060324.csv' }, { object_key: 'PPUD_MPC_20250325160328.csv' }] }

      it 'imports the CSV file from the S3 bucket' do
        allow(Rails.logger).to receive(:info).and_call_original
        subject.import_from_s3_bucket(date)

        expect(Rails.logger).to have_received(:info).with(
          /Found 2 files with prefix PPUD_MPC_20250325\. Importing PPUD_MPC_20250325160328\.csv/
        )
        expect(ParoleReviewImport.count).to eq(2)
      end
    end

    context 'when no files are found in the S3 bucket' do
      let(:s3_files) { [] }

      it 'logs a warning message' do
        allow(Rails.logger).to receive(:warn).and_call_original
        subject.import_from_s3_bucket(date)

        expect(Rails.logger).to have_received(:warn).with(
          /No files found with prefix PPUD_MPC_20250325/
        )
      end
    end
  end
end
