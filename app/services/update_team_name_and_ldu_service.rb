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

    return unless name_needs_updating? || ldu_needs_updating?

    if name_needs_updating?
      @team.name = @team_name
    end

    if ldu_needs_updating?
      ldu = LocalDivisionalUnit.find_by(code: @ldu_code)
      @team.local_divisional_unit = ldu
      return Rails.logger.error("Couldn't find LDU with code #{@ldu_code}") if ldu.nil?
    end

    @team.save
  end

private

  def name_needs_updating?
    @team.name != @team_name
  end

  def ldu_needs_updating?
    @team.local_divisional_unit&.code != @ldu_code
  end
end
