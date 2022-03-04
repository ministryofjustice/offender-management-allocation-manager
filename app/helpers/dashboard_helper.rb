module DashboardHelper
  def display_content(case_counts, no_cases:, one_case:, multiple_cases:)
    case case_counts
    when 0
      no_cases
    when 1
      one_case
    else
      multiple_cases
    end
  end
end
