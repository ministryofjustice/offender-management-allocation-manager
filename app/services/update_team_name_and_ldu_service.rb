class UpdateTeamNameAndLduService
  def self.update(team_code:, team_name:, ldu_code:)
    new(team_code: team_code, team_name: team_name, ldu_code: ldu_code).update
  end

  def initialize(team_code:, team_name:, ldu_code:)
    @team = Team.find_by(code: team_code)
    @team_name = team_name
    @ldu_code = ldu_code

    Rails.logger.error("Couldn't find team with code #{team_code}") if @team.nil?
  end

  def update
    return if @team.nil?

    update_name if name_needs_updating?
    update_ldu if ldu_needs_updating?
    @team.save if @team.changed?
  end

private

  def name_needs_updating?
    @team.name != @team_name
  end

  def update_name
    @team.name = @team_name
  end

  def ldu_needs_updating?
    @team.local_divisional_unit&.code != @ldu_code
  end

  def update_ldu
    ldu = LocalDivisionalUnit.find_by(code: @ldu_code)
    return Rails.logger.error("Couldn't find LDU with code #{@ldu_code}") if ldu.nil?

    @team.local_divisional_unit = ldu
  end
end
