# frozen_string_literal: true

module OverrideHelper
  def complex_reason_label(recommended_type)
    if recommended_type == 'Prison officer'
      return 'Prisoner assessed as not suitable for a prison officer POM'
    end

    'Prisoner assessed as suitable for a prison officer POM despite tiering calculation'
  end
end
