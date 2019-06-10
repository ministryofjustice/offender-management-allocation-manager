require 'rails_helper'

describe Nomis::Models::OffenderSummary, model: true do
  it "handles no earliest date" do
    o = described_class.new
    o.sentence = Nomis::Models::SentenceDetail.new
    expect(o.sentence.earliest_release_date).to be_nil
    expect(o.sentenced?).to be false
  end

  it "handles an earliest date" do
    o = described_class.new.tap { |off|
      off.sentence = Nomis::Models::SentenceDetail.new
      off.sentence.sentence_start_date = Date.new(2005, 2, 3)
      off.sentence.release_date = Date.new(2010, 1, 1)
      off.sentence.parole_eligibility_date = Date.new(2009, 1, 1)
    }
    expect(o.sentence.earliest_release_date).to eq(Date.new(2009, 1, 1))
    expect(o.sentenced?).to be true
  end
end
