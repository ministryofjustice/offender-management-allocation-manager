# frozen_string_literal: true

module PomHelper
  def format_working_pattern(pattern)
    if pattern == '1.0'
      'Full time'
    else
      "Part time - #{pattern}"
    end
  end
end
