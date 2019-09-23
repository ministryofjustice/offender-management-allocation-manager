require 'rails_helper'

RSpec.describe SentenceType, type: :model do
  it 'can return a sentence type for an offender with known sentence' do
    sentence_type = described_class.new('IPP')

    expect(sentence_type.code).to eq('IPP')
    expect(sentence_type.description).to eq('Indeterminate Sent for Public Protection')
    expect(sentence_type.duration_type).to eq(SentenceType::INDETERMINATE)
    expect(sentence_type.recall_status).to eq(SentenceType::NON_RECALL)
  end

  it 'can handle offenders with no sentence' do
    sentence_type = described_class.new(nil)

    expect(sentence_type.code).to eq('UNK_SENT')
    expect(sentence_type.description).to eq('Unknown Sentenced')
    expect(sentence_type.duration_type).to eq(SentenceType::DETERMINATE)
  end

  it 'knows what a civil sentence is' do
    expect(described_class.new('CIVIL').civil?).to be true
    expect(described_class.new('IPP').civil?).to be false
  end

  it "can determine determinate sentences" do
    off = described_class.new 'CRIM_CON'

    expect(off.indeterminate_sentence?).to eq false
  end

  it "can determine indeterminate sentences" do
    off = described_class.new 'IPP'

    expect(off.indeterminate_sentence?).to eq true
  end

  it "can determine recall sentences" do
    off = described_class.new 'LR_HDC'

    expect(off.recall_sentence?).to eq true
  end

  it "can determine non-recall sentences" do
    off = described_class.new 'IPP'

    expect(off.recall_sentence?).to eq false
  end

  it "can describe a sentence for an offender" do
    off = described_class.new 'IPP'
    desc = off.description

    expect(desc).to eq('Indeterminate Sent for Public Protection')
  end
end
