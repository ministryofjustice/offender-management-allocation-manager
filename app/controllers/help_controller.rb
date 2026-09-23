class HelpController < ApplicationController
  def missing_cases
    @prison_code = default_prison_code
  end

  def case_responsibility; end
end
