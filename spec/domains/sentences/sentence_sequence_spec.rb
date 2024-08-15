require "rails_helper"

describe Sentences::SentenceSequence do
  def term(attrs = {}) = Sentences::SentenceTerm.new(attrs)

  def terms(tsv)
    headers = 'sentenceSequence,termSequence,sentenceType,sentenceTypeDescription,startDate,lifeSentence,caseId,sentenceTermCode,lineSeq,sentenceStartDate,years'.split(',')
    CSV.parse(tsv).map { |row| term(headers.zip(row).to_h) }
  end

  describe "sentence term groupings" do
    subject(:concurrent_sentences) { described_class.from(sentences_terms) }

    let(:sentences_terms) do
      [
        term('caseId' => 1, 'sentenceStartDate' => 10.years.ago, 'months' => 10, 'lifeSentence' => false, 'sentenceSequence' => 1, 'termSequence' => 1),
        term('caseId' => 1, 'sentenceStartDate' => 10.years.ago, 'months' => 2, 'lifeSentence' => true, 'sentenceSequence' => 1, 'termSequence' => 2),
        term('caseId' => 2, 'sentenceStartDate' => 5.years.ago, 'days' => 2, 'sentenceSequence' => 1, 'termSequence' => 1),
        term('caseId' => 3, 'sentenceStartDate' => 2.years.ago, 'years' => 3, 'sentenceSequence' => 1, 'termSequence' => 1),
      ]
    end

    it 'groups sentence terms by case id' do
      expect(concurrent_sentences.count).to eq(3)
    end

    it 'orders each group by sentence start date ascening' do
      expect(concurrent_sentences.first.sentence_start_date.to_date).to eq(10.years.ago.to_date)
      expect(concurrent_sentences.second.sentence_start_date.to_date).to eq(5.years.ago.to_date)
      expect(concurrent_sentences.third.sentence_start_date.to_date).to eq(2.years.ago.to_date)
    end

    it 'sums up sentence durations within the group' do
      expect(concurrent_sentences.first.duration).to eq(1.year)
      expect(concurrent_sentences.second.duration).to eq(2.days)
      expect(concurrent_sentences.third.duration).to eq(3.years)
    end

    it 'considers sentence indeterminate if any of the terms are marked as life' do
      expect(concurrent_sentences.first).to be_indeterminate
      expect(concurrent_sentences.second).not_to be_indeterminate
      expect(concurrent_sentences.third).not_to be_indeterminate
    end

    context 'with many duplicate rows and different case ids' do
      let(:sentences_terms) do
        terms <<~CSV
          8,1,LIFE,Life Imprisonment or Detention S.53(1) CYPA 1933,01/01/2005,TRUE,100050,IMP,8,01/01/2005
          9,1,LIFE,Life Imprisonment or Detention S.53(1) CYPA 1933,01/01/2005,TRUE,100050,IMP,9,01/01/2005
          10,1,LIFE,Life Imprisonment or Detention S.53(1) CYPA 1933,01/01/2005,TRUE,100050,IMP,10,01/01/2005,6
          11,1,LIFE,Life Imprisonment or Detention S.53(1) CYPA 1933,01/01/2005,TRUE,100050,IMP,11,01/01/2005
          12,1,LIFE,Life Imprisonment or Detention S.53(1) CYPA 1933,01/01/2005,TRUE,100050,IMP,12,01/01/2005
          13,1,LIFE,Life Imprisonment or Detention S.53(1) CYPA 1933,01/01/2005,TRUE,100050,IMP,13,01/01/2005
          14,1,LIFE,Life Imprisonment or Detention S.53(1) CYPA 1933,01/01/2005,TRUE,100050,IMP,14,01/01/2005
          15,1,LR_LIFE,Recall to Custody Indeterminate Sentence,01/01/2004,TRUE,200050,IMP,15,01/01/2004,2
          15,1,LR_LIFE,Recall to Custody Indeterminate Sentence,01/01/2004,TRUE,200050,IMP,15,01/01/2004,2
          16,1,LR_LIFE,Recall to Custody Indeterminate Sentence,01/01/2004,TRUE,200050,IMP,16,01/01/2004
          17,1,LR_LIFE,Recall to Custody Indeterminate Sentence,01/01/2004,TRUE,200050,IMP,17,01/01/2004
          18,1,LR_LIFE,Recall to Custody Indeterminate Sentence,01/01/2004,TRUE,200050,IMP,18,01/01/2004
          19,1,LR_LIFE,Recall to Custody Indeterminate Sentence,01/01/2004,TRUE,200050,IMP,19,01/01/2004
          20,1,LR_LIFE,Recall to Custody Indeterminate Sentence,01/01/2004,TRUE,200050,IMP,20,01/01/2004
          21,1,LR_LIFE,Recall to Custody Indeterminate Sentence,01/01/2004,TRUE,200050,IMP,21,01/01/2004
          22,1,LR_LIFE,Recall to Custody Indeterminate Sentence,01/01/2004,TRUE,200050,IMP,22,01/01/2004
          23,1,LR_LIFE,Recall to Custody Indeterminate Sentence,01/01/2004,TRUE,200050,IMP,23,01/01/2004
          24,1,LR_LIFE,Recall to Custody Indeterminate Sentence,01/01/2004,TRUE,200050,IMP,24,01/01/2004
          25,1,LR_LIFE,Recall to Custody Indeterminate Sentence,01/01/2004,TRUE,200050,IMP,25,01/01/2004
          26,1,LR_LIFE,Recall to Custody Indeterminate Sentence,01/01/2004,TRUE,200050,IMP,26,01/01/2004
          27,1,ADIMP,Sentencing Code Standard Determinate Sentence,01/01/2007,FALSE,300050,IMP,27,01/01/2007,2
          28,1,ADIMP,Sentencing Code Standard Determinate Sentence,01/01/2007,FALSE,300050,IMP,28,01/01/2007,6
        CSV
      end

      it 'does not duplicate the rows in the resulting sequence' do
        expect(concurrent_sentences.count).to be(3)
        expect(concurrent_sentences.first.sentence_start_date.to_date).to eq(Date.parse('01/01/2004'))
        expect(concurrent_sentences.first.duration).to eq(2.years)
        expect(concurrent_sentences.second.sentence_start_date.to_date).to eq(Date.parse('01/01/2005'))
        expect(concurrent_sentences.second.duration).to eq(6.years)
        expect(concurrent_sentences.third.sentence_start_date.to_date).to eq(Date.parse('01/01/2007'))
        expect(concurrent_sentences.third.duration).to eq(8.years)
      end
    end

    context 'with duplicate rows within the same case id' do
      let(:sentences_terms) do
        terms <<~CSV
          1,1,IPP,Indeterminate Sentence for the Public Protection,01/01/2005,TRUE,200000,IMP,1,01/01/2005
          2,1,IPP,Indeterminate Sentence for the Public Protection,01/01/2005,TRUE,200000,IMP,2,01/01/2005,99
          1,1,IPP,Indeterminate Sentence for the Public Protection,01/01/2005,TRUE,200000,IMP,1,01/01/2005
          2,1,IPP,Indeterminate Sentence for the Public Protection,01/01/2005,TRUE,200000,IMP,2,01/01/2005,99
          1,1,IPP,Indeterminate Sentence for the Public Protection,01/01/2005,TRUE,200000,IMP,1,01/01/2005
          2,1,IPP,Indeterminate Sentence for the Public Protection,01/01/2005,TRUE,200000,IMP,2,01/01/2005,99
        CSV
      end

      it 'does not duplicate the rows in the resulting sequence' do
        expect(concurrent_sentences.count).to be(1)
        expect(concurrent_sentences.first.sentence_start_date.to_date).to eq(Date.parse('01/01/2005'))
        expect(concurrent_sentences.first.duration).to eq(99.years)
      end
    end
  end
end
