module DashboardHelper
  def display_content(case_counts, no_cases:, one_case:, multiple_cases:)
    if case_counts == 0
      no_cases
    elsif case_counts == 1
      one_case
    else
      multiple_cases
    end
  end
end
