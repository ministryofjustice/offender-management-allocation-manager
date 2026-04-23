describe CaseInformation do
  let(:case_info) { create(:case_information) }
  let(:rosh_level_feature_enabled) { true }

  before do
    stub_rosh_level_feature(enabled: rosh_level_feature_enabled)
  end

  context 'with mappa level' do
    subject { build(:case_information) }

    it 'allows 0, 1, 2, 3 and nil' do
      (described_class::MAPPA_LEVELS + [nil]).each do |level|
        subject.mappa_level = level
        expect(subject).to be_valid
      end
    end

    it 'does not allow 4' do
      subject.mappa_level = 4
      expect(subject).not_to be_valid
    end
  end

  context 'with rosh level' do
    subject { build(:case_information) }

    it 'allows LOW, MEDIUM, HIGH, VERY_HIGH and nil' do
      (described_class::ROSH_LEVELS + [nil]).each do |level|
        subject.rosh_level = level
        expect(subject).to be_valid
      end
    end

    it 'does not allow unexpected values' do
      subject.rosh_level = 'UNKNOWN'

      expect(subject).not_to be_valid
    end

    it 'requires a rosh level for manual entry' do
      subject.rosh_level = nil

      expect(subject.valid?(:manual_entry)).to be(false)
      expect(subject.errors.messages).to include(rosh_level: ['Select ROSH'])
    end

    context 'when the rosh feature flag is disabled' do
      let(:rosh_level_feature_enabled) { false }

      it 'does not require a rosh level for manual entry' do
        subject.rosh_level = nil

        expect(subject.valid?(:manual_entry)).to be(true)
      end
    end

    it 'treats a blank rosh level as missing for manual entry' do
      subject.rosh_level = ''

      expect(subject.valid?(:manual_entry)).to be(false)
      expect(subject.errors.messages).to include(rosh_level: ['Select ROSH'])
    end
  end

  context 'with basic factory' do
    subject do
      build(:case_information)
    end

    it { is_expected.to be_valid }
  end

  context 'with unsupported tier' do
    subject do
      build(:case_information, tier: 'N/A')
    end

    it 'is not valid' do
      expect(subject).not_to be_valid
      expect(subject.errors.messages).to eq(tier: ['Select tier'])
    end
  end

  context 'with missing tier' do
    subject do
      build(:case_information, tier: nil)
    end

    it 'gives the correct message' do
      expect(subject).not_to be_valid
      expect(subject.errors.messages).to eq(tier: ['Select tier'])
    end
  end

  context 'with manual flag' do
    it 'will be valid' do
      expect(build(:case_information, manual_entry: true)).to be_valid
    end
  end

  context 'without manual flag' do
    it 'will be valid' do
      expect(build(:case_information)).to be_valid
    end
  end

  context 'with null manual flag' do
    it 'wont be valid' do
      expect(build(:case_information, manual_entry: nil)).not_to be_valid
    end
  end

  describe 'enhanced_resourcing' do
    let(:valid_cases) { [true, false] }

    context "when receiving values from nDelius job" do
      it 'can be true' do
        expect(build(:case_information, enhanced_resourcing: true).valid?).to be(true)
      end

      it 'can be false' do
        expect(build(:case_information, enhanced_resourcing: false).valid?).to be(true)
      end

      it 'can be nil' do
        expect(build(:case_information, enhanced_resourcing: nil).valid?).to be(true)
      end
    end

    context 'when manually entering values from the missing details form' do
      it 'can be true' do
        expect(build(:case_information, enhanced_resourcing: true, rosh_level: 'HIGH').valid?(:manual_entry)).to be(true)
      end

      it 'can be false' do
        expect(build(:case_information, enhanced_resourcing: false, rosh_level: 'HIGH').valid?(:manual_entry)).to be(true)
      end

      it 'cannot be nil' do
        expect(build(:case_information, enhanced_resourcing: nil, rosh_level: 'HIGH').valid?(:manual_entry)).to be(false)
      end
    end
  end

  describe '#complete_for_allocation?' do
    it 'is true when tier and rosh level are present' do
      expect(build(:case_information, tier: 'A', rosh_level: 'HIGH', enhanced_resourcing: false).complete_for_allocation?).to be(true)
    end

    it 'is true when enhanced resourcing is missing' do
      expect(build(:case_information, tier: 'A', rosh_level: 'HIGH', enhanced_resourcing: nil).complete_for_allocation?).to be(true)
    end

    it 'is false when rosh level is missing' do
      expect(build(:case_information, rosh_level: nil).complete_for_allocation?).to be(false)
    end

    context 'when the rosh feature flag is disabled' do
      let(:rosh_level_feature_enabled) { false }

      it 'is true when rosh level is missing' do
        expect(build(:case_information, tier: 'A', rosh_level: nil).complete_for_allocation?).to be(true)
      end
    end

    it 'is false when tier is missing' do
      expect(build(:case_information, tier: nil, rosh_level: 'HIGH').complete_for_allocation?).to be(false)
    end
  end
end
