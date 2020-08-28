require 'rails_helper'

RSpec.describe SentenceType, type: :model do
  it 'can return a sentence type for an offender with known sentence' do
    sentence_type = described_class.new('IPP', false)

    expect(sentence_type.code).to eq('IPP')
    expect(sentence_type.description).to eq('Indeterminate Sent for Public Protection')
    expect(sentence_type.indeterminate_sentence?).to eq(true)
    expect(sentence_type.recall_sentence?).to eq(false)
  end

  it 'can handle offenders with no sentence' do
    sentence_type = described_class.new(nil, nil)

    expect(sentence_type.code).to eq('UNK_SENT')
    expect(sentence_type.description).to eq('Unknown Sentenced')
    expect(sentence_type.indeterminate_sentence?).to eq(false)
  end

  it 'knows what a civil sentence is' do
    expect(described_class.new('CIVIL', nil).civil?).to be true
    expect(described_class.new('IPP', nil).civil?).to be false
  end

  it "can determine determinate sentences" do
    off = described_class.new 'CRIM_CON', nil

    expect(off.indeterminate_sentence?).to eq false
  end

  it "can determine indeterminate sentences" do
    off = described_class.new 'IPP', nil

    expect(off.indeterminate_sentence?).to eq true
  end

  it "can determine recall sentences" do
    off = described_class.new nil, true

    expect(off.recall_sentence?).to eq true
  end

  it "can determine non-recall sentences" do
    off = described_class.new 'IPP', false

    expect(off.recall_sentence?).to eq false
  end

  it "can describe a sentence for an offender" do
    off = described_class.new 'IPP', nil
    desc = off.description

    expect(desc).to eq('Indeterminate Sent for Public Protection')
  end
end
