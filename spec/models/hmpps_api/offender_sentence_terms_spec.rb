require "rails_helper"

describe HmppsApi::OffenderSentenceTerms do
  describe '#sentenced_to_an_additional_isp?' do
    subject { described_class.new(offender_sentence_terms) }

    context "when the offender has multiple indeterminate sentence terms" do
      context "and those ISP terms are over different cases" do
        context "and one term appears after the other" do
          let(:offender_sentence_terms) do
            sentence_start_date = 2.years.ago
            [
              HmppsApi::OffenderSentenceTerm.new('lifeSentence' => true, 'caseId' => 1, 'sentenceStartDate' => sentence_start_date),
              HmppsApi::OffenderSentenceTerm.new('lifeSentence' => true, 'caseId' => 1, 'sentenceStartDate' => sentence_start_date),
              HmppsApi::OffenderSentenceTerm.new('lifeSentence' => true, 'caseId' => 2, 'sentenceStartDate' => sentence_start_date), # same as case 1
              HmppsApi::OffenderSentenceTerm.new('lifeSentence' => true, 'caseId' => 3, 'sentenceStartDate' => sentence_start_date + 1.day), # greater than case 2
            ]
          end

          it 'is sentenced to an additional isp' do
            expect(subject).to be_additional_isp
          end
        end

        context "and all term dates are the same" do
          let(:offender_sentence_terms) do
            sentence_start_date = 1.year.ago
            [
              HmppsApi::OffenderSentenceTerm.new('lifeSentence' => true, 'caseId' => 1, 'sentenceStartDate' => sentence_start_date),
              HmppsApi::OffenderSentenceTerm.new('lifeSentence' => true, 'caseId' => 1, 'sentenceStartDate' => sentence_start_date),
              HmppsApi::OffenderSentenceTerm.new('lifeSentence' => true, 'caseId' => 2, 'sentenceStartDate' => sentence_start_date),
              HmppsApi::OffenderSentenceTerm.new('lifeSentence' => true, 'caseId' => 3, 'sentenceStartDate' => sentence_start_date)
            ]
          end

          it 'is not sentenced to an additional isp' do
            expect(subject).not_to be_additional_isp
          end
        end
      end

      context "and those IPS terms are all the same case" do
        let(:offender_sentence_terms) do
          [
            HmppsApi::OffenderSentenceTerm.new('lifeSentence' => true, 'caseId' => 1, 'sentenceStartDate' => nil),
            HmppsApi::OffenderSentenceTerm.new('lifeSentence' => true, 'caseId' => 1, 'sentenceStartDate' => nil)
          ]
        end

        it 'is not sentenced to an additional isp' do
          expect(subject).not_to be_additional_isp
        end
      end
    end

    context "when the offender does not have multiple indeterminate sentence terms" do
      let(:offender_sentence_terms) { [HmppsApi::OffenderSentenceTerm.new('lifeSentence' => true, 'caseId' => 1, 'sentenceStartDate' => nil)] }

      it 'is not sentenced to an additional isp' do
        expect(subject).not_to be_additional_isp
      end
    end

    context "when the offender does not have any indeterminate sentence terms" do
      let(:offender_sentence_terms) { [HmppsApi::OffenderSentenceTerm.new(indeterminate?: false, 'caseId' => 1, 'sentenceStartDate' => nil)] }

      it 'is not sentenced to an additional isp' do
        expect(subject).not_to be_additional_isp
      end
    end

    context "when the offender does not have any sentence terms at all" do
      let(:offender_sentence_terms) { [] }

      it 'is not sentenced to an additional isp' do
        expect(subject).not_to be_additional_isp
      end
    end
  end
end
