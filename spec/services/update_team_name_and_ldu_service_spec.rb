require 'rails_helper'

RSpec.describe UpdateTeamNameAndLduService do
  context "when the team has the wrong name" do
    before do
      team = create(:team, code: 'TEAM1', name: 'The wrong team name')
      team.local_divisional_unit.code = 'LDU1'
      team.local_divisional_unit.save
    end

    it "updates the team name" do
      described_class.update(team_code: 'TEAM1', team_name: 'Team One', ldu_code: 'LDU1')
      team = Team.find_by(code: 'TEAM1')
      expect(team.name).to eq('Team One')
    end
  end

  context "when the team doesn't have an associated LDU" do
    before do
      team = build(:team, code: 'TEAM1', name: 'Team One')
      team.local_divisional_unit = nil
      team.save(validate: false)
      create(:local_divisional_unit, code: 'LDU1')
    end

    it "associates the team with the LDU" do
      described_class.update(team_code: 'TEAM1', team_name: 'Team One', ldu_code: 'LDU1')
      team = Team.find_by(code: 'TEAM1')
      expect(team.local_divisional_unit.code).to eq('LDU1')
    end
  end

  context "when the team is associated with the wrong LDU" do
    before do
      create(:team, code: 'TEAM1', name: 'Team One')
      create(:local_divisional_unit, code: 'LDU1')
    end

    it "associates the team with the correct LDU" do
      described_class.update(team_code: 'TEAM1', team_name: 'Team One', ldu_code: 'LDU1')
      team = Team.find_by(code: 'TEAM1')
      expect(team.local_divisional_unit.code).to eq('LDU1')
    end
  end

  context "when the team name and LDU are already correct" do
    before do
      team = create(:team, code: 'TEAM1', name: 'Team One')
      team.local_divisional_unit.code = 'LDU1'
      team.local_divisional_unit.save
    end

    it "doesn't update the team record" do
      expect_any_instance_of(Team).not_to receive(:save)
      described_class.update(team_code: 'TEAM1', team_name: 'Team One', ldu_code: 'LDU1')
    end
  end
end
