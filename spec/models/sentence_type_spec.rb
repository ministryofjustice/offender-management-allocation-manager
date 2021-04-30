# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SentenceType, type: :model do
  it 'can return a sentence type for an offender with known sentence' do
    sentence_type = described_class.new('IPP')

    expect(sentence_type.code).to eq('IPP')
  end

  it 'can handle offenders with no sentence' do
    sentence_type = described_class.new(nil)

    expect(sentence_type.code).to eq('UNK_SENT')
  end

  it 'knows what a civil sentence is' do
    expect(described_class.new('CIVIL').civil_sentence?).to be true
    expect(described_class.new('IPP').civil_sentence?).to be false
  end
end
