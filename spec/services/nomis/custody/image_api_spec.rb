require 'rails_helper'

describe Nomis::Custody::ImageApi do
  describe '#fetching an image' do
    it "can get a user's jpg",
       vcr: { cassette_name: :image_api_spec } do
      data = described_class.image_data('G7998GJ')
      expect(data).not_to be_nil

      # JPEG files start with FF D8 FF as the first three bytes ...
      # .. and end with FF D9 as the last two bytes. This should be
      # an adequate test to see if we receive a valid JPG from the
      # API call.
      jpeg_start_sentinel = [0xFF, 0xD8, 0xFF]
      jpeg_end_sentinel = [0xFF, 0xD9]

      bytes = data.bytes.to_a
      expect(bytes[0, 3]).to eq(jpeg_start_sentinel)
      expect(bytes[-2, 2]).to eq(jpeg_end_sentinel)
    end
  end
end
