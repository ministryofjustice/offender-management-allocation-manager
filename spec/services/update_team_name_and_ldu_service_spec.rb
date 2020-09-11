require 'rails_helper'

RSpec.describe UpdateTeamNameAndLduService do
  context "when the team has the wrong name" do
    before do
      ldu = create(:local_divisional_unit)
      create(:team, code: 'TEAM1', name: 'The wrong team name', local_divisional_unit: ldu)
    end

    let(:team) { Team.first }
    let(:ldu) { team.local_divisional_unit }

    it "updates the team name" do
      described_class.update(team_code: 'TEAM1', team_name: 'Team One', ldu_code: ldu.code, ldu_name: ldu.name)
      expect(team.reload.name).to eq('Team One')
    end
  end

  context "when the team doesn't have an associated LDU" do
    before do
      team = build(:team, code: 'TEAM1', name: 'Team One')
      team.local_divisional_unit = nil
      team.save(validate: false)
      create(:local_divisional_unit, code: 'LDU1')
    end

    let(:ldu) { LocalDivisionalUnit.first }

    it "associates the team with the LDU" do
      described_class.update(team_code: 'TEAM1', team_name: 'Team One', ldu_code: ldu.code, ldu_name: ldu.name)
      team = Team.find_by(code: 'TEAM1')
      expect(team.local_divisional_unit.code).to eq('LDU1')
    end
  end

  context "when the team is associated with the wrong LDU" do
    before do
      create(:team, code: 'TEAM1', name: 'Team One')
      create(:local_divisional_unit, code: 'LDU1')
    end

    let(:ldu) { LocalDivisionalUnit.find_by!(code: 'LDU1') }

    it "associates the team with the correct LDU" do
      described_class.update(team_code: 'TEAM1', team_name: 'Team One', ldu_code: ldu.code, ldu_name: ldu.name)
      team = Team.find_by(code: 'TEAM1')
      expect(team.local_divisional_unit.code).to eq('LDU1')
    end
  end

  context "when the team name and LDU are already correct" do
    before do
      create(:team, code: 'TEAM1', name: 'Team One')
    end

    let(:team) { Team.first }

    it "doesn't update the team record" do
      expect_any_instance_of(Team).not_to receive(:save)
      described_class.update(team_code: 'TEAM1', team_name: 'Team One', ldu_code: team.local_divisional_unit.code, ldu_name: team.local_divisional_unit.name)
    end
  end

  context "when a team with the specified code doesn't exist" do
    before do
      create(:local_divisional_unit)
    end

    let(:ldu) { LocalDivisionalUnit.first }

    it "creates a new team" do
      expect {
        described_class.update(team_code: 'TEAM1', team_name: 'Team One', ldu_code: ldu.code, ldu_name: ldu.name)
      }.to change(Team, :count).by(1)
    end
  end

  context "when an LDU with the specified code doesn't exist" do
    before do
      create(:team, code: 'TEAM1')
    end

    let(:ldu) { build(:local_divisional_unit) }

    it "creates a new LDU" do
      expect {
        described_class.update(team_code: 'TEAM1', team_name: 'Team One', ldu_code: ldu.code, ldu_name: ldu.name)
      }.to change(LocalDivisionalUnit, :count).by(1)
    end
  end

  context 'with a duplicate team name' do
    before do
      create(:team, code: 'NTTR1', name: 'A team')
    end

    let(:ldu) { build(:local_divisional_unit) }

    it 'errors' do
      expect {
        described_class.update(team_code: 'NTTR2', team_name: 'A team', ldu_code: ldu.code, ldu_name: ldu.name)
      }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name has already been taken')
    end
  end

  context 'when a shadow team of the same name exists' do
    before do
      create(:team, code: nil, local_divisional_unit: nil)
      create(:local_divisional_unit)
    end

    let(:ldu) { LocalDivisionalUnit.last }

    let(:team) { Team.last }
    let(:team_code) { 'NTTR2' }

    it 'matches, and updates the LDU' do
      described_class.update(team_code: team_code, team_name: team.name, ldu_code: ldu.code, ldu_name: ldu.name)
      expect(team.reload.attributes.symbolize_keys.except(:id, :case_information_count, :created_at, :updated_at)).
        to eq(attributes_for(:team, shadow_code: team.shadow_code, code: team_code, name: team.name, local_divisional_unit_id: ldu.id))
    end
  end
end
