class HelpController < ApplicationController
  def missing_cases
    @prison_code = default_prison_code
  end

  def case_responsibility
    prison_code = default_prison_code
    staff_id = HmppsApi::NomisUserRolesApi.user_details(current_user).staff_id
    @case_updates_path = prison_staff_caseload_updates_required_path(prison_code, staff_id)
  end
end
