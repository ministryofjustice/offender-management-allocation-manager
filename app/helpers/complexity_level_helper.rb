module ComplexityLevelHelper
  COMPLEXITIES = { 'high' => 3, 'medium' => 2, 'low' => 1 }.freeze

  def display_complexity_change_info(previous_complexity_level:, updated_complexity_level:)
    if updated_complexity_level == 'high'
      render partial: 'complexity_levels/complexity_level_increase_to_high', locals: { previous_complexity_level: previous_complexity_level }
    elsif ['low', 'medium'].include?(updated_complexity_level) && previous_complexity_level == 'high'
      render partial: 'complexity_levels/complexity_level_lowered_from_high', locals: { updated_complexity_level: updated_complexity_level }
    else
      render partial: 'complexity_levels/complexity_level_change_medium_low'
    end
  end

  # this is required for sorting only
  def complexity_level_number level
    COMPLEXITIES.fetch(level)
  end
end
