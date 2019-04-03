require 'rails_helper'

describe SentenceTypeService do
  it "can determine determinate sentences" do
    off = Nomis::Models::OffenderShort.new.tap { |o| o.imprisonment_status = 'CRIM_CON' }

    expect(described_class.indeterminate_sentence?(off.imprisonment_status)).to eq false
  end

  it "can determine indeterminate sentences" do
    off = Nomis::Models::OffenderShort.new.tap { |o| o.imprisonment_status = 'IPP' }

    expect(described_class.indeterminate_sentence?(off.imprisonment_status)).to eq true
  end

  it "can describe a sentence for an offender" do
    off = Nomis::Models::OffenderShort.new.tap { |o| o.imprisonment_status = 'IPP' }
    desc = described_class.describe_sentence(off.imprisonment_status)

    expect(desc).to eq('Indeterminate Sent for Public Protection')
  end
end
