# frozen_string_literal: true

class BaseHistoryPresenter
private

  def paper_trail_created_by_name(version)
    full_name(version.user_first_name, version.user_last_name) || version.whodunnit.presence
  end

  def nomis_created_by_name(username)
    return if username.blank?

    user = HmppsApi::NomisUserRolesApi.user_details(username)
    full_name(user.first_name, user.last_name)
  end

  def full_name(first_name, last_name)
    [first_name, last_name].compact_blank.join(' ').presence
  end

  def system_admin_created_by_name(version)
    return unless version.system_admin_note.present? && version.whodunnit.present?

    "System Admin (#{version.whodunnit})"
  end
end
