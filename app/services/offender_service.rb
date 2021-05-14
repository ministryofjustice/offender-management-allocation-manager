# frozen_string_literal: true

class OffenderService
  def self.get_offender(offender_no)
    HmppsApi::PrisonApi::OffenderApi.get_offender(offender_no).tap { |o|
      next false if o.nil?

      record = CaseInformation.find_by(nomis_offender_id: offender_no)
      o.load_case_information(record)

      o.main_offence = HmppsApi::PrisonApi::OffenderApi.get_offence(o.booking_id)
    }
  end

  def self.get_community_data(nomis_offender_id)
    community_info = HmppsApi::CommunityApi::get_offender(nomis_offender_id).deep_symbolize_keys
    mappa_registrations = HmppsApi::CommunityApi::get_offender_registrations(nomis_offender_id).deep_symbolize_keys
                        .fetch(:registrations, [])
                        .select { |r|
                          r.fetch(:active) && r.key?(:registerLevel) && r.dig(:registerLevel, :code).starts_with?('M')
                        }
    com = community_info.fetch(:offenderManagers).detect { |om| om.fetch(:active) }
    {
        noms_no: nomis_offender_id,
        tier: community_info.fetch(:currentTier),
        crn: community_info.dig(:otherIds, :crn),
        service_provider: com.dig(:probationArea, :nps) ? 'NPS' : 'CRC',
        offender_manager: com.dig(:staff, :unallocated) ? nil : "#{com.dig(:staff, :surname)}, #{com.dig(:staff, :forenames)}",
        team_name: com.dig(:team, :description),
        ldu_code: com.dig(:team, :localDeliveryUnit, :code),
        mappa_levels: mappa_registrations.map { |r| r.dig(:registerLevel, :code).last.to_i }
    }
  end
end
