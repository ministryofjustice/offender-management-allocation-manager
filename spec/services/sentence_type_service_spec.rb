require 'rails_helper'

describe SentenceTypeService do
  it "can determine determinate sentences" do
    off = Nomis::Models::Offender.new.tap { |o| o.imprisonment_status = 'CRIM_CON' }

    expect(described_class.determinate_sentence?(off)).to eq true
  end

  it "can determine indeterminate sentences" do
    off = Nomis::Models::Offender.new.tap { |o| o.imprisonment_status = 'IPP' }

    expect(described_class.determinate_sentence?(off)).to eq false
  end

  it "can describe a sentence for an offender" do
    off = Nomis::Models::Offender.new.tap { |o| o.imprisonment_status = 'IPP' }
    desc = described_class.describe_sentence(off)

    expect(desc).to eq('Indeterminate Sent for Public Protection')
  end
end
