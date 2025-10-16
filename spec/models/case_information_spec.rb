describe CaseInformation do
  let(:case_info) { create(:case_information) }

  context 'with mappa level' do
    subject { build(:case_information) }

    it 'allows 0, 1, 2, 3 and nil' do
      [0, 1, 2, 3, nil].each do |level|
        subject.mappa_level = level
        expect(subject).to be_valid
      end
    end

    it 'does not allow 4' do
      subject.mappa_level = 4
      expect(subject).not_to be_valid
    end
  end

  context 'with basic factory' do
    subject do
      build(:case_information)
    end

    it { is_expected.to be_valid }
  end

  context 'with missing tier' do
    subject do
      build(:case_information, tier: nil)
    end

    it 'gives the correct message' do
      expect(subject).not_to be_valid
      expect(subject.errors.messages).to eq(tier: ['Select the prisoner’s tier'])
    end
  end

  context 'with manual flag' do
    it 'will be valid' do
      expect(build(:case_information, manual_entry: true)).to be_valid
    end
  end

  context 'without manual flag' do
    it 'will be valid' do
      expect(build(:case_information, manual_entry: false)).to be_valid
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
        expect(build(:case_information, enhanced_resourcing: true).valid?(:manual_entry)).to be(true)
      end

      it 'can be false' do
        expect(build(:case_information, enhanced_resourcing: false).valid?(:manual_entry)).to be(true)
      end

      it 'cannot be nil' do
        expect(build(:case_information, enhanced_resourcing: nil).valid?(:manual_entry)).to be(false)
      end
    end
  end
end
