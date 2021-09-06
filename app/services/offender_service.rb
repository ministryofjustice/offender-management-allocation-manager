# frozen_string_literal: true

class OffenderService
  class << self
    def get_offender(offender_no)
      # use find_or_create_by here for performance, but might still have be a small race condition
      # This isn't find_or_create_by! because our offender_no might be invalid - we want to return nil rather than crash
      offender = Offender.find_or_create_by(nomis_offender_id: offender_no)
      api_offender = HmppsApi::PrisonApi::OffenderApi.get_offender(offender_no)
      prison = Prison.find_by(code: api_offender&.prison_id)

      if [offender, api_offender, prison].all?(&:present?)
        MpcOffender.new(
          prison: prison,
          offender: offender,
          prison_record: api_offender
        )
      end
    end

    def get_offenders_in_prison(prison)
      api_offenders = HmppsApi::PrisonApi::OffenderApi.get_offenders_in_prison(prison.code)
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
      community_info = HmppsApi::CommunityApi::get_offender(nomis_offender_id).deep_symbolize_keys
      mappa_registrations = HmppsApi::CommunityApi::get_offender_registrations(nomis_offender_id).deep_symbolize_keys
                              .fetch(:registrations, [])
                              .select { |r|
                                r.fetch(:active) && r.key?(:registerLevel) && r.dig(:registerLevel, :code).starts_with?('M')
                              }

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
          mappa_levels: mappa_registrations.map { |r| r.dig(:registerLevel, :code).last.to_i }
        }
    end

  private

    def find_or_create_offenders(nomis_ids)
      offenders = Offender.
        includes(:early_allocations, :responsibility, case_information: [:local_delivery_unit]).
        where(nomis_offender_id: nomis_ids)

      if offenders.count != nomis_ids.count
        # Create Offender records for (presumably new) prisoners who don't have one yet
        existing_ids = offenders.map(&:nomis_offender_id)
        (nomis_ids - existing_ids).each do |new_id|
          # use create_or_find_by! to prevent race conditions
          new_offender = Offender.create_or_find_by! nomis_offender_id: new_id
          offenders = offenders + [new_offender]
        end
      end

      offenders
    end
  end
end
