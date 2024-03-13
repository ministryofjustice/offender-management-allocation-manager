require "rails_helper"

describe OffenderSampleService do
  describe "filtering the provided offenders" do
    let(:recall_offender) do
      double("recall_offender",
             indeterminate_sentence?: false,
             recalled?: true,
             full_name: "Creswell, Ciril",
             case_information: double,
             release_date: 2.years.from_now)
    end
    let(:sentence_indeterminate_offender) do
      double("sentence_indeterminate_offender",
             indeterminate_sentence?: true,
             recalled?: false,
             full_name: "Alfa, Alf",
             case_information: double,
             release_date: 2.years.from_now)
    end
    let(:sentence_determinate_offender) do
      double("sentence_determinate_offender",
             indeterminate_sentence?: false,
             recalled?: false,
             full_name: "Alfa, Alf",
             case_information: double,
             release_date: 2.years.from_now)
    end

    let(:offenders) { [recall_offender, sentence_indeterminate_offender, sentence_determinate_offender] }

    describe "specifying a single criteria" do
      it "returns only offenders matching the chosen criteria" do
        results = described_class.new(offenders:, criteria: [:badge_recall]).results
        expect(results).to match_array([recall_offender])
      end
    end

    describe "specifying multiple critera" do
      it "applies the filtering using OR logic" do
        results = described_class.new(offenders:, criteria: [:badge_sentence_indeterminate, :badge_recall]).results
        expect(results).to match_array([recall_offender, sentence_indeterminate_offender])
      end
    end

    context "when offender does not have a release date in the future and badge_sentence_indeterminate is not a chosen criteria" do
      let(:recall_offender_with_release_date_in_past) do
        double("recall_offender_with_release_date_in_past",
               indeterminate_sentence?: false,
               recalled?: true,
               full_name: "Jones, Jane",
               case_information: double,
               release_date: 2.seconds.ago)
      end

      let(:recall_offender_with_no_release_date) do
        double("recall_offender_with_no_release_date",
               indeterminate_sentence?: true,
               recalled?: true,
               full_name: "Bones, Bill",
               case_information: double,
               release_date: nil)
      end

      let(:offenders) { [recall_offender, recall_offender_with_release_date_in_past, recall_offender_with_no_release_date] }

      it "does not return any offenders without a future release_date" do
        results = described_class.new(offenders:, criteria: [:badge_recall]).results
        expect(results).to match_array([recall_offender])
      end

      context "when including indeterminate_sentence in the chosen crietiera" do
        it "ignores release_dates for indeterminate_sentence offenders" do
          results = described_class.new(offenders:, criteria: [:badge_sentence_indeterminate, :badge_recall]).results
          expect(results).to match_array([recall_offender, recall_offender_with_no_release_date])
        end
      end
    end
  end

  it "must supply either a prison_code or list of offenders from the OffenderService" do
    expect { described_class.new }.to raise_error(ArgumentError)
    expect { described_class.new(offenders: []) }.not_to raise_error
    expect { described_class.new(prison_code: "") }.not_to raise_error
  end
end
