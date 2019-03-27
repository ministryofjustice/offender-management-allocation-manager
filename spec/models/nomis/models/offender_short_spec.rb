require 'rails_helper'

describe Nomis::Models::OffenderShort, model: true do
  it "handles no earliest date" do
    o = described_class.new
    expect(o.earliest_release_date).to be_nil
    expect(o.sentenced?).to be false
  end

  it "handles an earliest date" do
    o = described_class.new.tap { |off|
      off.release_date = Date.new(2010, 1, 1)
      off.parole_eligibility_date = Date.new(2009, 1, 1)
    }
    expect(o.earliest_release_date).to eq(Date.new(2009, 1, 1))
    expect(o.sentenced?).to be true
  end
end
