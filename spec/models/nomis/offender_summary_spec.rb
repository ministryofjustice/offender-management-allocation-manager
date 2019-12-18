require 'rails_helper'

describe Nomis::OffenderSummary, model: true do
  it "handles no earliest date" do
    o = described_class.new
    o.sentence = Nomis::SentenceDetail.new
    expect(o.sentenced?).to be false
  end

  it "handles an earliest date" do
    o = described_class.new.tap { |off|
      off.sentence = Nomis::SentenceDetail.new
      off.sentence.sentence_start_date = Date.new(2005, 2, 3)
      off.sentence.release_date = Date.new(2010, 1, 1)
      off.sentence.parole_eligibility_date = Date.new(2009, 1, 1)
    }
    expect(HandoverDateService.earliest_release_date(o.sentence)).to eq(Date.new(2009, 1, 1))
    expect(o.sentenced?).to be true
  end
end
