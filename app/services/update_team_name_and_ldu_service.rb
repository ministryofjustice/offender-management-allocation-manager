# frozen_string_literal: true

class UpdateTeamNameAndLduService
  def self.update(team_code:, team_name:, ldu_code:, ldu_name:)
    ldu = LocalDivisionalUnit.find_or_create_by!(code: ldu_code) do |l|
      l.name = ldu_name
    end
    # If there is a code-less team with this name, match to it as it used to be a 'shadow-only' team
    existing_team = Team.find_by(name: team_name)
    if existing_team.present? && existing_team.code.nil?
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
