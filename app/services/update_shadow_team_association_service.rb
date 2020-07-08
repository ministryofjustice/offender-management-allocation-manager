# frozen_string_literal: true

class UpdateShadowTeamAssociationService
  def self.update(shadow_code:, shadow_name:)
    active_name = shadow_name_to_active_name shadow_name

    Team.find_or_initialize_by(name: active_name).tap do |team|
      team.shadow_code = shadow_code
      team.save! if team.changed?
    end
  end

private

  def self.shadow_name_to_active_name shadow_name
    match = shadow_name.match(/^\*?OMIC ?-? (.*)$/i)

    if match.nil?
      raise("This doesn't look like a shadow team name: '#{shadow_name}'")
    end

    match[1]
  end
end
