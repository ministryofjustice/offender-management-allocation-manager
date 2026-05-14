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

  it 'recognises the configured civil sentence types' do
    expect(described_class::CIVIL_SENTENCE_TYPES).to all(satisfy { |code| described_class.new(code).civil_sentence? })
  end

  it 'treats upstream fine-code variants as civil sentences' do
    expect(described_class.new('A/FINE').civil_sentence?).to be true
    expect(described_class.new('A_FINE').civil_sentence?).to be true
  end

  it 'does not treat criminal sentence types as civil' do
    expect(described_class.new('IPP').civil_sentence?).to be false
  end

  describe '#recall?' do
    it 'recognises the current upstream Prison API recall sentence codes' do
      expect(described_class::RECALL_SENTENCE_TYPES).to all(satisfy { |code| described_class.new(code).recall? })
    end

    it 'does not treat non-recall sentence codes as recall' do
      expect(described_class.new('ADIMP_ORA').recall?).to be false
      expect(described_class.new('EDS21').recall?).to be false
    end
  end
end
