module PrisonHelper
  def show_prison_switcher?(caseloads)
    caseloads.present? && caseloads.count > 1
  end

  def prison_title(prison)
    PrisonService.name_for(prison)
  end
end
