require 'rails_helper'

describe Nomis::Elite2::OffenderApi do
  describe 'List of offenders' do
    it "can get a list of offenders",
       vcr: { cassette_name: :offender_api_offender_list } do
      response = described_class.list('LEI')

      expect(response.data).not_to be_nil
      expect(response.data).to be_instance_of(Array)
      expect(response.data).to all(be_an Nomis::OffenderSummary)
    end

    it "can get an offence description for a booking id",
       vcr: { cassette_name: :offender_api_get_offence_ok } do
      booking_id = '1153753'
      response = described_class.get_offence(booking_id)
      expect(response).to be_instance_of(String)
      expect(response).to eq 'Section 18 - wounding with intent to resist / prevent arrest'
    end

    it "returns category codes",
       vcr: { cassette_name: :offender_api_offender_category_list } do
      response = described_class.list('LEI')
      expect(response.data.first.category_code).not_to be_nil
    end
  end

  describe 'Bulk operations' do
    it 'can get bulk sentence details',
       vcr: { cassette_name: :offender_api_bulk_sentence_details } do
      booking_ids = [1_153_753]

      response = described_class.get_bulk_sentence_details(booking_ids)

      expect(response).to be_instance_of(Hash)

      records = response.values
      expect(records.first).to be_instance_of(Nomis::SentenceDetail)
      expect(records.first.release_date).to eq(Date.new(2020, 2, 7))
      expect(records.first.full_name).to eq('Abbella, Ozullirn')
    end
  end

  describe 'Multiple offenders' do
    let!(:offenders) {
      %w[G4273GI G7806VO G3462VT G1670VU G5897GP G3536UF G7998GJ G2407UH G4879UP G8060UF]
    }

    it 'can get multiple offenders',
       vcr: { cassette_name: :offender_api_multiple_offenders_spec } do
      response = described_class.get_multiple_offenders(offenders)

      expect(response.first).to be_instance_of(Nomis::Offender)
      expect(response.count).to eq(10)
    end

    it 'can handle getting an empty list',
       vcr: { cassette_name: :offender_api_multiple_offenders_empty_spec } do
      response = described_class.get_multiple_offenders([])
      expect(response.count).to eq(0)
    end

    it 'can return results as a hash',
       vcr: { cassette_name: :offender_api_multiple_offenders_hash_spec } do
      h = described_class.get_multiple_offenders_as_hash(offenders)

      expect(h).to be_instance_of(Hash)
      expect(h.key? offenders.first).not_to be_nil
    end
  end

  describe 'Single offender' do
    it "can get a single offender's details",
       vcr: { cassette_name: :offender_api_single_offender_spec } do
      noms_id = 'G2911GD'

      response = described_class.get_offender(noms_id)

      expect(response).to be_instance_of(Nomis::Offender)
    end

    it 'can get category codes', :raven_intercept_exception,
       vcr: { cassette_name: :offender_api_cat_code_spec } do
      noms_id = 'G4273GI'
      response = described_class.get_category_code(noms_id)
      expect(response).to eq('C')
    end

    it 'returns if unable to find prisoner',
       vcr: { cassette_name: :offender_api_null_offender_spec  } do
      noms_id = 'AAA22D'

      response = described_class.get_offender(noms_id)

      expect(response).to be_nil
    end
  end

  describe 'fetching an image' do
    it "can get a user's jpg",
       vcr: { cassette_name: :offender_api_image_spec } do
      booking_id = 1_153_753
      response = described_class.get_image(booking_id)

      expect(response).not_to be_nil

      # JPEG files start with FF D8 FF as the first three bytes ...
      # .. and end with FF D9 as the last two bytes. This should be
      # an adequate test to see if we receive a valid JPG from the
      # API call.
      jpeg_start_sentinel = [0xFF, 0xD8, 0xFF]
      jpeg_end_sentinel = [0xFF, 0xD9]

      bytes = response.bytes.to_a
      expect(bytes[0, 3]).to eq(jpeg_start_sentinel)
      expect(bytes[-2, 2]).to eq(jpeg_end_sentinel)
    end
  end
end
