require "rails_helper"

describe "Responsibility and Handover",  handover_calculations: true do
  let(:responsibility) { HandoverDateService.handover(mpc_offender) }
  let(:isps) { [Sentences::SentenceSequence.new] }

  before do
    allow(Sentences).to receive(:for).with(booking_id: mpc_offender.booking_id).and_return(isps)
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
  end
end
