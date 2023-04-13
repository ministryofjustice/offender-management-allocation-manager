# frozen_string_literal: true

class OffenderService
  class << self
    def get_offender(offender_no, ignore_legal_status: false)
      # use find_or_create_by here for performance, but might still have be a small race condition
      # This isn't find_or_create_by! because our offender_no might be invalid - we want to return nil rather than crash
      offender = Offender.find_or_create_by(nomis_offender_id: offender_no)
      return unless offender

      api_offender = HmppsApi::PrisonApi::OffenderApi.get_offender(offender_no,
                                                                   ignore_legal_status: ignore_legal_status)
      return unless api_offender

      prison = Prison.find_by(code: api_offender.prison_id)
      return unless prison

      MpcOffender.new(
        prison: prison,
        offender: offender,
        prison_record: api_offender
      )
    end

    def get_offenders_in_prison(prison, include_remand: false)
      api_offenders = HmppsApi::PrisonApi::OffenderApi.get_offenders_in_prison(prison.code, include_remand: include_remand)
                                                      .index_by(&:offender_no)

      offenders = find_or_create_offenders(api_offenders.keys)

      offenders.map do |offender|
        MpcOffender.new(
          prison: prison,
          offender: offender,
          prison_record: api_offenders.fetch(offender.nomis_offender_id)
        )
      end
    end

    def get_community_data(nomis_offender_id)
      community_info = HmppsApi::CommunityApi.get_offender(nomis_offender_id).deep_symbolize_keys
      registrations = HmppsApi::CommunityApi.get_offender_registrations(nomis_offender_id).deep_symbolize_keys.fetch(:registrations, [])

      mappa_registrations = registrations.select do |r|
        r.fetch(:active) && r.key?(:registerLevel) && r.dig(:registerLevel, :code).starts_with?('M')
      end

      is_nps = begin
        HmppsApi::CommunityApi.get_latest_resourcing(nomis_offender_id)
                              .fetch('enhancedResourcing')
      rescue Faraday::ResourceNotFound, KeyError
        true # default to NPS if 404 Not Found or no enhancedResourcing field present in the response
      end

      com = community_info.fetch(:offenderManagers).detect { |om| om.fetch(:active) }

      {
        noms_no: nomis_offender_id,
        tier: community_info.fetch(:currentTier),
        crn: community_info.dig(:otherIds, :crn),
        service_provider: is_nps ? 'NPS' : 'CRC',
        offender_manager: com.dig(:staff, :unallocated) ? nil : "#{com.dig(:staff, :surname)}, #{com.dig(:staff, :forenames)}",
        team_name: com.dig(:team, :description),
        ldu_code: com.dig(:team, :localDeliveryUnit, :code),
        mappa_levels: mappa_registrations.map { |r| r.dig(:registerLevel, :code).last.to_i },
        active_vlo: registrations.any? { |r| r.fetch(:active) && %w[INVI DASO].include?(r.dig(:type, :code)) }
      }
    end

    def get_com(nomis_offender_id)
      oms = HmppsApi::CommunityApi.get_all_offender_managers(nomis_offender_id)
      com = oms.detect { |om| om['isPrisonOffenderManager'] == false }

      personal_details = if com['isUnallocated']
                           {
                             name: nil,
                             email: nil,
                             is_unallocated: true,
                           }
                         else
                           staff = com.fetch('staff')
                           {
                             name: [staff.fetch('surname'), staff.fetch('forenames')].join(', '),
                             email: staff['email'],
                             is_unallocated: false,
                           }
                         end
      personal_details.merge({
        is_responsible: com.fetch('isResponsibleOfficer'),
        team_name: com.fetch('team').fetch('description'),
        ldu_code: com.fetch('team').fetch('localDeliveryUnit').fetch('code'),
      })
    end

    def get_mappa_details(crn)
      nil_details = { category: nil, level: nil, short_description: nil, review_date: nil, start_date: nil }

      return nil_details if crn.blank?

      details = HmppsApi::CommunityApi.get_offender_mappa_details(crn)

      {
        category: details['category'],
        level: details['level'],
        short_description: "CAT #{details['category']}/LEVEL #{details['level']}",
        review_date: Date.parse(details['reviewDate']),
        start_date: Date.parse(details['startDate'])
      }
    rescue Faraday::ResourceNotFound
      nil_details
    end

  private

    def find_or_create_offenders(nomis_ids)
      offenders = Offender
        .includes(:early_allocations, :responsibility, case_information: [:local_delivery_unit])
        .where(nomis_offender_id: nomis_ids)

      if offenders.count != nomis_ids.count
        # Create Offender records for (presumably new) prisoners who don't have one yet
        existing_ids = offenders.map(&:nomis_offender_id)
        (nomis_ids - existing_ids).each do |new_id|
          # use create_or_find_by! to prevent race conditions
          new_offender = Offender.create_or_find_by! nomis_offender_id: new_id
          offenders += [new_offender]
        end
      end

      offenders
    end
  end
end
