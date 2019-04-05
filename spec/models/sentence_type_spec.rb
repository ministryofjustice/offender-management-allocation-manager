require 'rails_helper'

RSpec.describe SentenceType, type: :model do
  it 'can return a sentence type for an offender with known sentence' do
    off = Nomis::Models::OffenderSummary.new.tap { |o| o.imprisonment_status = 'IPP' }
    sentence_type = described_class.create(off.imprisonment_status)

    expect(sentence_type.code).to eq('IPP')
    expect(sentence_type.description).to eq('Indeterminate Sent for Public Protection')
    expect(sentence_type.duration_type).to eq(SentenceType::INDETERMINATE)
  end

  it 'can handle offenders with no sentence' do
    off = Nomis::Models::OffenderSummary.new
    sentence_type = described_class.create(off.imprisonment_status)

    expect(sentence_type.code).to eq('UNK_SENT')
    expect(sentence_type.description).to eq('Unknown Sentenced')
    expect(sentence_type.duration_type).to eq(SentenceType::DETERMINATE)
  end
end
