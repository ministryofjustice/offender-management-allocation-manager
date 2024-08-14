require 'rails_helper'

describe Sentences::SentenceTerm do
  it { is_expected.not_to be_indeterminate }

  context 'when it is a life sentence' do
    subject { described_class.new('lifeSentence' => true) }

    it { is_expected.to be_indeterminate }
  end

  context 'when the sentence type is indeterminate' do
    Sentences::SentenceTerm::SentenceType::INDETERMINATE_SENTENCE_TYPES.each do |indeterminate_type|
      subject { described_class.new('sentenceType' => indeterminate_type) }

      it { is_expected.to be_indeterminate }
    end
  end

  describe 'durations' do
    {
      { 'days' => 5 } => 5.days,
      { 'months' => 10 } => 10.months,
      { 'months' => 36 } => 3.years,
      { 'months' => 5, 'days' => 5 } => (5.months + 5.days),
      { 'years' => 1 } => 1.year,
      { 'years' => 1, 'months' => 12 } => 2.years,
      { 'years' => 1, 'months' => 13 } => (2.years + 1.month),
    }.each do |attributes, expected_duration|
      it "calculates duration as an accumulation of date parts (#{attributes} -> #{expected_duration.inspect})" do
        expect(described_class.new(attributes).duration).to eq(expected_duration)
      end
    end
  end
end
