# frozen_string_literal: true

class UpdateTeamNameAndLduService
  def self.update(team_code:, team_name:, ldu_code:, ldu_name:)
    ldu = LocalDivisionalUnit.find_or_create_by!(code: ldu_code) do |l|
      l.name = ldu_name
    end
    existing_teams = Team.where(name: team_name).reject { |t| t.code == team_code }
    # If this looks like an NPS team, and there is an unique existing team with this name but different code, match to it
    if Team.new(code: team_code, name: team_name, local_divisional_unit: ldu).nps? && existing_teams.count == 1
      existing_team = existing_teams.first
      existing_team.assign_attributes(code: team_code, local_divisional_unit: ldu)
      existing_team.save! if existing_team.changed?
    else
      Team.find_or_initialize_by(code: team_code).tap do |team|
        team.assign_attributes(name: team_name, local_divisional_unit: ldu)
        team.save! if team.changed?
      end
    end
  end
end
