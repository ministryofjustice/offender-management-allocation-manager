class HelpController < ApplicationController
  def missing_cases
    @prison_code = default_prison_code
  end

  def case_responsibility
    prison_code = default_prison_code
    @case_updates_path = prison_staff_caseload_updates_required_path(prison_code, current_staff_id)
  end
end
