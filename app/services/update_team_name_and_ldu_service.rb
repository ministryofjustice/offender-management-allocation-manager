class UpdateTeamNameAndLduService
  def self.update(team_code:, team_name:, ldu_code:, ldu_name:)
    ldu = LocalDivisionalUnit.find_or_create_by!(code: ldu_code) do |l|
      l.name = ldu_name
    end
    Team.find_or_initialize_by(code: team_code).tap do |t|
      t.assign_attributes(name: team_name, local_divisional_unit: ldu)
      t.save if t.changed?
    end
  end
end
