class UpdateShadowTeamAssociationService
  def self.update(shadow_code:, shadow_name:)
    new(shadow_code: shadow_code, shadow_name: shadow_name).update
  end

  def initialize(shadow_code:, shadow_name:)
    @shadow_code = shadow_code
    @shadow_name = shadow_name
    @team = find_active_team
  end

  def update
    return if @team.nil?

    if @team.shadow_code != @shadow_code
      @team.update(shadow_code: @shadow_code)
    end
  end

private

  def shadow_name_to_active_name
    match = @shadow_name.match(/^OMIC ?-? (.*)$/i)

    if match.nil?
      Rails.logger.error("This doesn't look like a shadow team name: '#{@shadow_name}'")
      return nil
    end

    match[1]
  end

  def find_active_team
    active_name = shadow_name_to_active_name
    return if active_name.nil?

    team = Team.find_by(name: active_name)

    if team.nil?
      Rails.logger.error("Couldn't find a team named '#{active_name}' to associate with shadow team '#{@shadow_name}'")
      return nil
    end

    team
  end
end
