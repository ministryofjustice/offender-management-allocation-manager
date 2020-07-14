# frozen_string_literal: true

class CaseInformationService
  def self.get_case_information(offender_ids)
    CaseInformation.includes(:early_allocations, team: :local_divisional_unit).
      where(nomis_offender_id: offender_ids).index_by(&:nomis_offender_id)
  end

  def self.ldu_changed?(team_ids)
    return false if team_ids.blank?

    return false if team_ids.last.nil? # from eng/wales to scot/ni

    return true if team_ids.first.nil? # from scot/ni to eng/wales

    old_ldu = Team.find_by(id: team_ids.first).try(:local_divisional_unit)
    new_ldu = Team.find_by(id: team_ids.last).try(:local_divisional_unit)
    old_ldu != new_ldu
  end
end
