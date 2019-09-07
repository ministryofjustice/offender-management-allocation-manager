require 'rails_helper'

describe OffenderService::SentenceDetails do
  let(:booking_id) { 1_153_753 }
  let(:fake_booking_id) { 0 }

  it "can retrieve the sentence details for a booking", vcr: { cassette_name: :sentence_details_spec } do
    details = described_class.call([booking_id])
    expect(details).to be_kind_of(Hash)
    expect(details.length).to eq(1)
    expect(details[booking_id]).to be_kind_of(Nomis::Models::SentenceDetail)
  end

  it "returns an empty hash when no ids are found", vcr: { cassette_name: :sentence_details_spec } do
    details = described_class.call([fake_booking_id])
    expect(details).to be_kind_of(Hash)
    expect(details.length).to eq(0)
  end
end
