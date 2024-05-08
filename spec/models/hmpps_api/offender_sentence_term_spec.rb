require 'rails_helper'

describe HmppsApi::OffenderSentenceTerm do
  it { is_expected.not_to be_indeterminate }

  context 'when it is a life sentence' do
    subject { described_class.new('lifeSentence' => true) }

    it { is_expected.to be_indeterminate }
  end

  context 'when the sentence type is indeterminate' do
    HmppsApi::OffenderSentenceTerm::SentenceType::INDETERMINATE_SENTENCE_TYPES.each do |indeterminate_type|
      subject { described_class.new('sentenceType' => indeterminate_type) }

      it { is_expected.to be_indeterminate }
    end
  end
end
