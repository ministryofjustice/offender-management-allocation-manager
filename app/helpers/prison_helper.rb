# frozen_string_literal: true

module PrisonHelper
  def show_prison_switcher?(caseloads)
    caseloads.present? && caseloads.count > 1
  end

  def prison_title(prison)
    PrisonService.name_for(prison)
  end

  def prison_switcher_path(prison, path)
    # They may be no referrer - go to dashboard
    if path.present?
      # remove /prisons/LEI from URL (which the split turns into ['', 'prisons', 'LEI'])
      paths = path.split('/')[3..].join('/')
      "/prisons/#{prison}/#{paths}"
    else
      "/prisons/#{prison}/dashboard"
    end
  end
end
