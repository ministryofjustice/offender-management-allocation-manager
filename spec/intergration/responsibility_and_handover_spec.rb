require "rails_helper"

describe "Responsibility and Handover",  handover_calculations: true do
  let(:responsibility) { HandoverDateService.handover(mpc_offender) }
  let(:isps) { [] }

  before do
    stub_const('USE_PPUD_PAROLE_DATA', true)
    allow(OffenderService).to receive(:get_offender_sentences_and_offences).with(mpc_offender.booking_id).and_return(isps)
    Timecop.freeze(Time.zone.local(2024, 5, 20))
  end

  after do
    Timecop.return
  end

  describe "Persona: Robin Hoodwink" do
    let(:mpc_offender) { build(:mpc_offender, :with_persona, :robin_hoodwink) }

    it "is COM responsible" do
      expect(responsibility).to be_com_responsible
    end

    it "was handed over from POM to COM was 12 months prior to TED" do
      expect(responsibility.handover_date).to eq(Date.parse("20th January 2024"))
    end
  end

  describe "Persona: Clarke Kentish" do
    let(:mpc_offender) { build(:mpc_offender, :with_persona, :clarke_kentish) }

    it "is COM responsible" do
      expect(responsibility).to be_com_responsible
    end
  end

  describe "Persona: Jane Heart" do
    let(:mpc_offender) { build(:mpc_offender, :with_persona, :jane_heart) }

    it "is POM responsible" do
      expect(responsibility).to be_pom_responsible
    end
  end

  describe "Persona: Adam Leant" do
    let(:mpc_offender) { build(:mpc_offender, :with_persona, :adam_leant) }

    it "is POM responsible" do
      expect(responsibility).to be_pom_responsible
    end
  end

  describe "Persona: Paul McCain" do
    let(:mpc_offender) { build(:mpc_offender, :with_persona, :paul_mccain) }

    it "is COM responsible" do
      expect(responsibility).to be_com_responsible
    end
  end

  describe "Persona: Peggy Sueis" do
    let(:mpc_offender) { build(:mpc_offender, :with_persona, :peggy_sueis) }

    it "is COM responsible" do
      expect(responsibility).to be_com_responsible
    end
  end

  describe "Persona: Nelly Theeleph" do
    let(:mpc_offender) { build(:mpc_offender, :with_persona, :nelly_theeleph) }

    it "is COM responsible" do
      expect(responsibility).to be_com_responsible
    end
  end

  describe "Persona: Seymore Tress" do
    let(:mpc_offender) { build(:mpc_offender, :with_persona, :seymore_tress) }

    it "is COM responsible" do
      expect(responsibility).to be_com_responsible
    end

    it "was handed over from POM to COM was 12 months prior to THD" do
      expect(responsibility.handover_date).to eq(Date.parse("10th May 2024"))
    end
  end

  describe "ISP Recall / Parole Responsibility rules" do
    context "when 12 months before TED" do
      let(:mpc_offender) { build(:mpc_offender, :with_persona, isp: true, ted: Date.parse("20th January 2025")) }

      it "is COM responsible" do
        expect(responsibility).to be_com_responsible
      end

      it "was handed over from POM to COM was 12 months prior to TED" do
        expect(responsibility.handover_date).to eq(Date.parse("20th January 2024"))
      end
    end

    context "when 12 months before THD" do
      let(:mpc_offender) do
        build(:mpc_offender, :with_persona, isp: true).tap do |offender|
          create(:parole_review,
                 nomis_offender_id: offender.nomis_offender_id,
                 hearing_outcome_received_on: Date.parse("12th May 2024"),
                 target_hearing_date: Date.parse("20th January 2025")
                )
        end
      end

      it "is COM responsible" do
        expect(responsibility).to be_com_responsible
      end

      it "was handed over from POM to COM was 12 months prior to THD" do
        expect(responsibility.handover_date).to eq(Date.parse("20th January 2024"))
      end
    end

    context "when after THD/TED awaiting parole decision" do
      let(:mpc_offender) do
        build(:mpc_offender, :with_persona, isp: true).tap do |offender|
          create(:parole_review,
                 nomis_offender_id: offender.nomis_offender_id,
                 target_hearing_date: Date.parse("1st May 2025")
                )
        end
      end

      it "is COM responsible" do
        expect(responsibility).to be_com_responsible
      end
    end

    context "when parole decision is release" do
      let(:mpc_offender) do
        build(:mpc_offender, :with_persona, isp: true, ted: Date.parse("1st May 2025")).tap do |offender|
          create(:parole_review,
                 nomis_offender_id: offender.nomis_offender_id,
                 hearing_outcome_received_on: Date.parse("1st May 2025"),
                 hearing_outcome: "Release [*]",
                 target_hearing_date: Date.parse("1st May 2025")
                )
        end
      end

      it "is COM responsible" do
        expect(responsibility).to be_com_responsible
      end
    end

    context "when parole decision is not to release AND THD less then 12 months in future" do
      let(:mpc_offender) do
        build(:mpc_offender, :with_persona, isp: true).tap do |offender|
          create(:parole_review,
                 nomis_offender_id: offender.nomis_offender_id,
                 hearing_outcome_received_on: Date.parse("1st May 2025"),
                 hearing_outcome: "Not at all Release [*]",
                 target_hearing_date: Date.parse("20th June 2024")
                )
        end
      end

      it "is COM responsible" do
        expect(responsibility).to be_com_responsible
      end
    end

    context "when parole decision is not to release AND THD more then 12 months in future AND mappa level is 1" do
      let(:mpc_offender) do
        build(:mpc_offender, :with_persona, isp: true, mappa_level: 1).tap do |offender|
          create(:parole_review,
                 nomis_offender_id: offender.nomis_offender_id,
                 hearing_outcome_received_on: Date.parse("1st May 2025"),
                 hearing_outcome: "Not at all Release [*]",
                 target_hearing_date: Date.parse("20th June 2025")
                )
        end
      end

      it "is POM responsible" do
        expect(responsibility).to be_pom_responsible
      end
    end

    context "when parole decision is not to release AND THD more then 12 months in future AND mappa level is 2" do
      let(:mpc_offender) do
        build(:mpc_offender, :with_persona, isp: true, mappa_level: 2).tap do |offender|
          create(:parole_review,
                 nomis_offender_id: offender.nomis_offender_id,
                 hearing_outcome_received_on: Date.parse("1st May 2025"),
                 hearing_outcome: "Not at all Release [*]",
                 target_hearing_date: Date.parse("20th June 2025")
                )
        end
      end

      it "is COM responsible" do
        expect(responsibility).to be_com_responsible
      end
    end

    context "with initial recalls" do
      let(:mpc_offender) { build(:mpc_offender, :with_persona, isp: true, recall: true, ted: Date.parse("20th January 2025")) }

      it "is COM responsible" do
        expect(responsibility).to be_com_responsible
      end
    end

    context "with an additional ISP" do
      let(:isps) { [double(indeterminate?: true, case_id: 1, sentence_start_date: 2.years.ago), double(indeterminate?: true, case_id: 2, sentence_start_date: 1.year.ago)] }
      let(:mpc_offender) { build(:mpc_offender, :with_persona, isp: true, recall: true, ted: Date.parse("20th January 2025")) }

      it "is POM only responsible" do
        expect(responsibility).to be_pom_responsible
        expect(responsibility).not_to be_com_supporting
      end
    end

    context "with ISP recall offenders with no earliest release date" do
      let(:mpc_offender) { build(:mpc_offender, :with_persona, isp: true, recall: true) }

      it "is COM responsible" do
        expect(responsibility).to be_com_responsible
        expect(responsibility.start_date).to be_nil
        expect(responsibility.handover_date).to be_nil
      end
    end
  end
end
