require 'rails_helper'

RSpec.describe CaseInformation, type: :model do
  let(:case_info) { create(:case_information) }

  it 'has timestamps' do
    expect(case_info.created_at).not_to be_nil
    sleep 2
    case_info.touch
    expect(case_info.updated_at).not_to eq(case_info.created_at)
  end

  describe '#early_allocations' do
    context 'when not setup' do
      it 'is empty' do
        expect(case_info.early_allocations).to be_empty
      end
    end

    context 'with an allocation' do
      let!(:early_allocation) { create(:early_allocation, nomis_offender_id: case_info.nomis_offender_id) }
      let!(:early_allocation2) { create(:early_allocation, nomis_offender_id: case_info.nomis_offender_id) }

      it 'has some entries' do
        expect(case_info.early_allocations).to eq([early_allocation, early_allocation2])
      end
    end
  end

  context 'with mappa level' do
    subject { build(:case_information, nomis_offender_id: '123456') }

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
    subject {
      build(:case_information)
    }

    it { is_expected.to be_valid }
  end

  describe '#manual_entry' do
    context 'when true' do
      it 'will be valid' do
        expect(build(:case_information, manual_entry: true)).to be_valid
      end
    end

    context 'when false' do
      it 'will be valid' do
        expect(build(:case_information, manual_entry: false)).to be_valid
      end
    end

    context 'when nil' do
      it 'will not be valid' do
        expect(build(:case_information, manual_entry: nil)).not_to be_valid
      end
    end
  end

  describe '#probation_service' do
    subject { build(:case_information, probation_service: nil) }

    it 'gives the correct validation error message' do
      expect(subject).not_to be_valid
      expect(subject.errors.messages).to eq(probation_service: ["You must say if the prisoner's last known address was in Northern Ireland, Scotland or Wales"])
    end

    it 'allows England, Wales, Scotland & Northern Ireland' do
      ['England', 'Wales', 'Scotland', 'Northern Ireland'].each do |service|
        subject.probation_service = service
        expect(subject).to be_valid
      end
    end
  end

  ['Scotland', 'Northern Ireland'].each do |country|
    context "when probation_service is #{country}" do
      subject {
        build(:case_information, probation_service: country,
              tier: 'A', case_allocation: 'NPS', team: build(:team)
        )
      }

      before do
        subject.valid?
      end

      it 'sets tier to N/A' do
        expect(subject.tier).to eq('N/A')
      end

      it 'sets case_allocation to N/A' do
        expect(subject.case_allocation).to eq('N/A')
      end

      it 'sets team to nil' do
        expect(subject.team).to be_nil
      end

      it 'is valid' do
        expect(subject.valid?).to be(true)
      end
    end
  end

  %w[England Wales].each do |country|
    context "when probation_service is #{country}" do
      subject {
        build(:case_information, probation_service: country,
              tier: 'A', case_allocation: 'NPS', team: build(:team)
        )
      }

      describe '#tier' do
        it 'gives the correct error message' do
          subject.tier = nil
          expect(subject).not_to be_valid
          expect(subject.errors.messages).to eq(tier: ["Select the prisoner's tier"])
        end

        it 'allows A, B, C, D' do
          %w[A B C D].each do |value|
            subject.tier = value
            expect(subject).to be_valid
          end
        end

        it 'does not allow other values' do
          [nil, 'E', 1, '0'].each do |value|
            subject.tier = value
            expect(subject).not_to be_valid
          end
        end
      end

      describe '#case_allocation' do
        it 'gives the correct error message' do
          subject.case_allocation = nil
          expect(subject).not_to be_valid
          expect(subject.errors.messages).to eq(case_allocation: ['Select the service provider for this case'])
        end

        it 'allows NPS, CRC' do
          %w[NPS CRC].each do |value|
            subject.case_allocation = value
            expect(subject).to be_valid
          end
        end

        it 'does not allow other values' do
          [nil, 'N/A', true].each do |value|
            subject.case_allocation = value
            expect(subject).not_to be_valid
          end
        end
      end

      describe '#team' do
        it 'cannot be blank' do
          subject.team = nil
          expect(subject).not_to be_valid
          expect(subject.errors.messages).to eq(team: ["You must select the prisoner's team"])
        end
      end
    end
  end

  describe '#ldu_changed?' do
    context 'when the team has not been changed' do
      subject { create(:case_information) }

      it 'returns false' do
        expect(subject.ldu_changed?).to be(false)
      end
    end

    context 'when the team has changed, but it belongs to the same LDU as the previous team' do
      subject { create(:case_information, team: team1) }

      let(:ldu) { create(:local_divisional_unit) }
      let(:team1) { create(:team, local_divisional_unit: ldu) }
      let(:team2) { create(:team, local_divisional_unit: ldu) }

      before { subject.team = team2 }

      it 'returns false' do
        expect(subject.ldu_changed?).to be(false)
      end
    end

    context 'when the team has changed and it belongs to a different LDU than the previous team' do
      subject { create(:case_information) }

      let(:new_team_and_ldu) { create(:team) }

      before { subject.team = new_team_and_ldu }

      it 'returns true' do
        expect(subject.ldu_changed?).to be(true)
      end

      describe 'once the changes have been saved to the database' do
        before { subject.save }

        it 'returns false' do
          expect(subject.ldu_changed?).to be(false)
        end
      end
    end

    context 'when the team has been set, where it was previously nil' do
      subject { create(:case_information, :no_team) }

      let(:team) { create(:team) }

      before { subject.team = team }

      it 'returns true' do
        expect(subject.ldu_changed?).to be(true)
      end
    end

    context 'when the team has been set to nil, where it previously belonged to an LDU' do
      subject { create(:case_information) }

      before { subject.team = nil }

      it 'returns true' do
        expect(subject.ldu_changed?).to be(true)
      end
    end
  end
end
