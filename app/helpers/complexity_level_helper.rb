module ComplexityLevelHelper
  def display_complexity_change_info(previous_complexity_level:, updated_complexity_level:)
    if updated_complexity_level == 'high'
      render partial: 'complexity_levels/complexity_level_increase_to_high', locals: { previous_complexity_level: previous_complexity_level }
    elsif ['low', 'medium'].include?(updated_complexity_level) && previous_complexity_level == 'high'
      render partial: 'complexity_levels/complexity_level_lowered_from_high', locals: { updated_complexity_level: updated_complexity_level }
    else
      render partial: 'complexity_levels/complexity_level_change_medium_low'
    end
  end
end
