require 'rails_helper'

describe Nomis::Elite2::OffenderApi do
  describe 'List of offenders' do
    it "can get a list of offenders",
      vcr: { cassette_name: :offender_api_offender_list } do
      response = described_class.list('LEI')

      expect(response.data).not_to be_nil
      expect(response.data).to be_instance_of(Array)
      expect(response.data).to all(be_an Nomis::Models::Offender)
    end

    it "can get an offence description for a booking id",
      vcr: { cassette_name: :offender_api_get_offence_ok } do
      booking_id = '1153753'
      response = described_class.get_offence(booking_id)
      expect(response).to be_instance_of(String)
      expect(response).to eq 'Section 18 - wounding with intent to resist / prevent arrest'
    end
  end

  describe 'Bulk operations' do
    it 'can get bulk sentence details',
      vcr: { cassette_name: :offender_api_bulk_sentence_details } do
      booking_ids = [1_153_753]

      response = described_class.get_bulk_sentence_details(booking_ids)

      expect(response).to be_instance_of(Hash)

      records = response.values
      expect(records.first).to be_instance_of(Nomis::Models::SentenceDetail)
      expect(records.first.release_date).to eq('2020-02-07')
      expect(records.first.full_name).to eq('Abbella, Ozullirn')
    end
  end

  describe 'Single offender' do
    it "can get a single offender's details",
      vcr: { cassette_name: :offender_api_single_offender_spec } do
      noms_id = 'G2911GD'

      response = described_class.get_offender(noms_id)

      expect(response).to be_instance_of(Nomis::Models::Offender)
    end

    it 'returns null if unable to find prisoner', :raven_intercept_exception,
      vcr: { cassette_name: :offender_api_null_offender_spec  } do
      noms_id = 'AAA22D'

      response = described_class.get_offender(noms_id)

      expect(response).to be_instance_of(Nomis::Models::NullOffender)
    end
  end
end
