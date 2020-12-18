require "rails_helper"

describe HmppsApi::SentenceDetail, model: true do
  let(:date) { Date.new(2019, 2, 3) }
  let(:override) { Date.new(2019, 5, 3) }

  describe "#automatic_release_date" do
    context "when override present" do
      subject {
        described_class.from_json 'automaticRelease_date' => date.to_s, 'automaticReleaseOverrideDate' => override.to_s
      }

      it "overrides" do
        expect(subject.automatic_release_date).to eq(override)
      end
    end

    context "without override" do
      subject {
        described_class.from_json('automaticReleaseDate' => date.to_s)
      }

      it "uses original" do
        expect(subject.automatic_release_date).to eq(date)
      end
    end
  end

  describe "#conditional_release_date" do
    context "when override present" do
      subject {
        described_class.from_json 'conditionalReleaseDate' => date.to_s, 'conditionalReleaseOverrideDate' => override.to_s
      }

      it "overrides" do
        expect(subject.conditional_release_date).to eq(override)
      end
    end

    context "without override" do
      subject {
        described_class.from_json('conditionalReleaseDate' => date.to_s)
      }

      it "uses original" do
        expect(subject.conditional_release_date).to eq(date)
      end
    end
  end

  describe "#nomis_post_recall_release_date" do
    context "when override present" do
      subject do
        described_class.from_json('postRecallReleaseDate' => date.to_s, 'postRecallReleaseOverrideDate' => override.to_s)
      end

      it "overrides" do
        expect(subject.nomis_post_recall_release_date).to eq(override)
      end
    end

    context "without override" do
      subject do
        described_class.from_json('postRecallReleaseDate' => date.to_s)
      end

      it "uses original" do
        expect(subject.nomis_post_recall_release_date).to eq(date)
      end
    end
  end

  describe "#post_recall_release_date" do
    subject {
      if actual_parole_date.nil?
        described_class.from_json 'automaticReleaseDate' => date.to_s,
                                  'automaticReleaseOverrideDate' => override.to_s
      else
        described_class.from_json 'automaticReleaseDate' => date.to_s,
                                  'automaticReleaseOverrideDate' => override.to_s,
                                  'actualParoleDate' => actual_parole_date.to_s
      end
    }

    let(:earliest_date) { Date.new(2019, 1, 2) }
    let(:latest_date) { Date.new(2019, 5, 4) }
    let(:no_date) { nil }


    before do
      allow(subject).to receive(:nomis_post_recall_release_date).and_return(nomis_post_recall_release_date)
    end

    context "when actual_parole_date comes before post_recall_release_date" do
      let(:actual_parole_date) { earliest_date }
      let(:nomis_post_recall_release_date) { latest_date }

      it "shows actual_parole_date" do
        expect(subject.post_recall_release_date).to eq(earliest_date)
      end
    end

    context "when actual_parole_date comes after post_recall_release_date" do
      let(:actual_parole_date) { latest_date }
      let(:nomis_post_recall_release_date) { earliest_date }

      it "shows post_recall_release_date" do
        expect(subject.post_recall_release_date).to eq(earliest_date)
      end
    end

    context "when post_recall_release_date is not present" do
      let(:actual_parole_date) { latest_date }
      let(:nomis_post_recall_release_date) { no_date }

      it "shows actual parole date" do
        expect(subject.post_recall_release_date).to eq(latest_date)
      end
    end

    context "when actual_parole_date and post_recall_release_date are not present" do
      let(:actual_parole_date) { no_date }
      let(:nomis_post_recall_release_date) { no_date }

      it "shows nil" do
        expect(subject.post_recall_release_date).to eq(no_date)
      end
    end
  end
end
