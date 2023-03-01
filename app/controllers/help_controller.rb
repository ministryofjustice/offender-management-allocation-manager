class HelpController < ApplicationController
  def missing_cases
    @prison_code = default_prison_code
  end

  def case_responsibility
    @prison_code = default_prison_code
    @staff_id = HmppsApi::PrisonApi::UserApi.user_details(current_user).staff_id
  end
end
