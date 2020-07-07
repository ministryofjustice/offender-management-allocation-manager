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
      expect(records.first.conditional_release_date).to eq(Date.new(2020, 3, 16))
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

    it "shows default image if there is no image available",
       vcr: { cassette_name: :offender_api_image_not_found } do
      booking_id = 1_153_753
      image_id = 1_340_556
      uri = "#{ApiHelper::T3}/images/#{image_id}/data"

      stub_request(:get, uri).to_return(status: 404)

      response = described_class.get_image(booking_id)
      default_image_file = Rails.root.join('app/assets/images/default_profile_image.jpg')

      image_bytes = File.read(default_image_file)
      expect(image_bytes).to eq(response)
    end

    it "uses a default image if there is no available image",
       vcr: { cassette_name: :offender_api_image_use_default_image } do
      booking_id = 1_153_753
      image_id = 1_340_556
      uri = "#{ApiHelper::T3}/images/#{image_id}/data"

      WebMock.stub_request(:get, uri).to_return(body: "")

      response = described_class.get_image(booking_id)
      expect(response).not_to be nil?

      jpeg_start_sentinel = [0xFF, 0xD8, 0xFF]
      jpeg_end_sentinel = [0xFF, 0xD9]

      bytes = response.bytes.to_a

      expect(bytes[0, 3]).to eq(jpeg_start_sentinel)
      expect(bytes[-2, 2]).to eq(jpeg_end_sentinel)
    end

    it "uses the default image if no offender facialImageId found",
       vcr: { cassette_name: :offender_api_no_facial_image_id } do
      booking_id = 1_153_753
      uri = "#{ApiHelper::T3}/offender-sentences/bookings"

      WebMock.stub_request(:post, uri).with(body: "[#{booking_id}]").to_return(
        body: [
          { "bookingId": 1_153_753,
            "dateOfBirth": "1953-04-15"
        }].to_json)

      response = described_class.get_image(booking_id)
      expect(response).not_to be nil?

      jpeg_start_sentinel = [0xFF, 0xD8, 0xFF]
      jpeg_end_sentinel = [0xFF, 0xD9]

      bytes = response.bytes.to_a

      expect(bytes[0, 3]).to eq(jpeg_start_sentinel)
      expect(bytes[-2, 2]).to eq(jpeg_end_sentinel)
    end
  end
end
