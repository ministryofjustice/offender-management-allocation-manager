require 'rails_helper'

RSpec.describe SentenceType, type: :model do
  it 'can return a sentence type for an offender with known sentence' do
    off = Nomis::Models::Offender.new.tap { |o| o.imprisonment_status = 'IPP' }
    sentence_type = described_class.create(off.imprisonment_status)

    expect(sentence_type.code).to eq('IPP')
    expect(sentence_type.description).to eq('Indeterminate Sent for Public Protection')
    expect(sentence_type.duration_type).to eq(SentenceType::INDETERMINATE)
  end

  it 'can handle offenders with no sentence' do
    off = Nomis::Models::Offender.new
    sentence_type = described_class.create(off.imprisonment_status)

    expect(sentence_type.code).to eq('UNK_SENT')
    expect(sentence_type.description).to eq('Unknown Sentenced')
    expect(sentence_type.duration_type).to eq(SentenceType::DETERMINATE)
  end

  it 'knows what a civil sentence is' do
    expect(described_class.civil?('CIVIL')).to be true
    expect(described_class.civil?('IPP')).to be false
  end
end
