require 'rails_helper'

RSpec.describe UpdateShadowTeamAssociationService do
  let(:team_name) { 'NPS - Team 1' }
  let(:team_shadow_code) { nil }
  let!(:team) { create(:team, name: team_name, shadow_code: team_shadow_code) }

  context "when the team doesn't have a shadow code" do
    it "sets the team's shadow code" do
      described_class.update(shadow_code: 'SHAD01', shadow_name: 'OMIC NPS - Team 1')
      expect(team.reload.shadow_code).to eq('SHAD01')
    end
  end

  context "when the team has a different shadow code" do
    let(:team_shadow_code) { 'A_DIFFERENT_SHADOW_CODE' }

    it "updates the team's shadow code" do
      described_class.update(shadow_code: 'SHAD01', shadow_name: 'OMIC NPS - Team 1')
      expect(team.reload.shadow_code).to eq('SHAD01')
    end
  end

  context "when the team already has the correct shadow code" do
    let(:team_shadow_code) { 'SHAD01' }

    it "doesn't update the team record" do
      expect_any_instance_of(Team).not_to receive(:save)
      described_class.update(shadow_code: 'SHAD01', shadow_name: 'OMIC NPS - Team 1')
    end
  end

  describe "shadow to active team name mappings" do
    example_team_names = {
      # "Shadow name" => "Active name"
      "OMIC Some Team" => "Some Team",
      "OMIC - NPS - Team 1" => "NPS - Team 1",
      "OMiC - Another team" => "Another team",
      "omic lowercase team" => "lowercase team"
    }

    example_team_names.each_with_index do |(shadow_name, active_name), index|
      context "shadow team '#{shadow_name}'" do
        let(:team_name) { active_name }

        it "maps to active team '#{active_name}'" do
          shadow_code = "SC#{index}"
          described_class.update(shadow_code: shadow_code, shadow_name: shadow_name)
          expect(team.reload.shadow_code).to eq(shadow_code)
        end
      end
    end
  end

  context "when the shadow name doesn't begin with 'OMIC'" do
    it "logs an error" do
      bad_shadow_name = 'Not a shadow team name'
      expect_message = "This doesn't look like a shadow team name: '#{bad_shadow_name}'"
      expect(Rails.logger).to receive(:error).with(expect_message)
      described_class.update(shadow_code: 'SHAD01', shadow_name: bad_shadow_name)
    end
  end

  context "when no active team exists with a matching name" do
    let(:team_name) { 'Some other team name' }

    it "creates a new team" do
      expect {
        described_class.update(shadow_code: 'SHAD01', shadow_name: 'OMIC Team 1')
      }.to change(Team, :count).by(1)
    end
  end
end
