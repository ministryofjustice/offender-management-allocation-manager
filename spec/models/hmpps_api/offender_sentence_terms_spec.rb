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
            expect(subject).to have_additional_isp
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
            expect(subject).not_to have_additional_isp
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
          expect(subject).not_to have_additional_isp
        end
      end
    end

    context "when the offender does not have multiple indeterminate sentence terms" do
      let(:offender_sentence_terms) { [HmppsApi::OffenderSentenceTerm.new('lifeSentence' => true, 'caseId' => 1, 'sentenceStartDate' => nil)] }

      it 'is not sentenced to an additional isp' do
        expect(subject).not_to have_additional_isp
      end
    end

    context "when the offender does not have any indeterminate sentence terms" do
      let(:offender_sentence_terms) { [HmppsApi::OffenderSentenceTerm.new(indeterminate?: false, 'caseId' => 1, 'sentenceStartDate' => nil)] }

      it 'is not sentenced to an additional isp' do
        expect(subject).not_to have_additional_isp
      end
    end

    context "when the offender does not have any sentence terms at all" do
      let(:offender_sentence_terms) { [] }

      it 'is not sentenced to an additional isp' do
        expect(subject).not_to have_additional_isp
      end
    end
  end

  describe '#concurrent_sentence_of_12_months_or_under?' do
    subject { described_class.new(offender_sentence_terms) }

    context 'when there are no sentences' do
      let(:offender_sentence_terms) { [] }

      it 'has no concurrent sentences of 12 months or under' do
        expect(subject).not_to have_concurrent_sentence_of_12_months_or_under
      end
    end

    context 'when there is only one sentence' do
      let(:offender_sentence_terms) { [HmppsApi::OffenderSentenceTerm.new('caseId' => 1)] }

      it 'has no concurrent sentences of 12 months or under' do
        expect(subject).not_to have_concurrent_sentence_of_12_months_or_under
      end
    end

    context 'when there are multiple sentences for the same case' do
      let(:offender_sentence_terms) {
        [
          HmppsApi::OffenderSentenceTerm.new('caseId' => 1),
          HmppsApi::OffenderSentenceTerm.new('caseId' => 1),
        ]
      }

      it 'has no concurrent sentences of 12 months or under' do
        expect(subject).not_to have_concurrent_sentence_of_12_months_or_under
      end
    end

    context 'when there are multiple sentences for different cases but none are under 12 months long' do
      let(:offender_sentence_terms) {
        [
          HmppsApi::OffenderSentenceTerm.new('caseId' => 1, 'months' => 13),
          HmppsApi::OffenderSentenceTerm.new('caseId' => 2, 'months' => 13),
        ]
      }

      it 'has no concurrent sentences of 12 months or under' do
        expect(subject).not_to have_concurrent_sentence_of_12_months_or_under
      end
    end

    context 'when there are multiple sentences for different cases' do
      {
        '12 months using months field' => [
          HmppsApi::OffenderSentenceTerm.new('caseId' => 1, 'months' => 12),
          HmppsApi::OffenderSentenceTerm.new('caseId' => 2),
        ],
        'over 12 months using year field'  => [
          HmppsApi::OffenderSentenceTerm.new('caseId' => 1, 'months' => 2, 'years' => 1),
          HmppsApi::OffenderSentenceTerm.new('caseId' => 2),
        ]
      }.each do |reason, terms|
        context "when one of the sentences is #{reason}" do
          it 'has no concurrent sentences of 12 months or under' do
            expect(described_class.new(terms)).to have_concurrent_sentence_of_12_months_or_under
          end
        end
      end
    end
  end

  describe '#concurrent_sentence_of_20_months_or_over?' do
    subject { described_class.new(offender_sentence_terms) }

    context 'when there are no sentences' do
      let(:offender_sentence_terms) { [] }

      it 'has no concurrent sentences of 20 months or over' do
        expect(subject).not_to have_concurrent_sentence_of_20_months_or_over
      end
    end

    context 'when there is only one sentence' do
      let(:offender_sentence_terms) { [HmppsApi::OffenderSentenceTerm.new('caseId' => 1)] }

      it 'has no concurrent sentences of 20 months or over' do
        expect(subject).not_to have_concurrent_sentence_of_20_months_or_over
      end
    end

    context 'when there are multiple sentences for the same case' do
      let(:offender_sentence_terms) {
        [
          HmppsApi::OffenderSentenceTerm.new('caseId' => 1),
          HmppsApi::OffenderSentenceTerm.new('caseId' => 1),
        ]
      }

      it 'has no concurrent sentences of 20 months or over' do
        expect(subject).not_to have_concurrent_sentence_of_20_months_or_over
      end
    end

    context 'when there are multiple sentences for different cases but none are under 12 months long' do
      let(:offender_sentence_terms) {
        [
          HmppsApi::OffenderSentenceTerm.new('caseId' => 1, 'months' => 19),
          HmppsApi::OffenderSentenceTerm.new('caseId' => 2, 'months' => 13),
        ]
      }

      it 'has no concurrent sentences of 20 months or over' do
        expect(subject).not_to have_concurrent_sentence_of_20_months_or_over
      end
    end

    context 'when there are multiple sentences for different cases' do
      {
        '20 months using months field' => [
          HmppsApi::OffenderSentenceTerm.new('caseId' => 1, 'months' => 20),
          HmppsApi::OffenderSentenceTerm.new('caseId' => 2),
        ],
        '21 months using months field' => [
          HmppsApi::OffenderSentenceTerm.new('caseId' => 1, 'months' => 21),
          HmppsApi::OffenderSentenceTerm.new('caseId' => 2),
        ],
        'over 20 months using months and days field' => [
          HmppsApi::OffenderSentenceTerm.new('caseId' => 1, 'months' => 20, 'days' => 1),
          HmppsApi::OffenderSentenceTerm.new('caseId' => 2),
        ],
        '20 months using months and year field'  => [
          HmppsApi::OffenderSentenceTerm.new('caseId' => 1, 'months' => 8, 'years' => 1),
          HmppsApi::OffenderSentenceTerm.new('caseId' => 2),
        ]
      }.each do |reason, terms|
        context "when one of the sentences is #{reason}" do
          it 'has no concurrent sentences of 20 months or over' do
            expect(described_class.new(terms)).to have_concurrent_sentence_of_20_months_or_over
          end
        end
      end
    end
  end
end
