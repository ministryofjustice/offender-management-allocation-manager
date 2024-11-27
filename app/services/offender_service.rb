# frozen_string_literal: true

class OffenderService
  def self.get_offender(offender_no, ignore_legal_status: false)
    prison_record = HmppsApi::PrisonApi::OffenderApi.get_offender(offender_no, ignore_legal_status:)
    return unless prison_record

    prison = Prison.find_by(code: prison_record.prison_id)
    return unless prison

    MpcOffender.new(prison:, prison_record:)
  end

  def self.get_offenders_in_prison(prison, ignore_legal_status: false)
    prison_records = HmppsApi::PrisonApi::OffenderApi.get_offenders_in_prison(prison.code, ignore_legal_status:)
    prison_records.map { |prison_record| MpcOffender.new(prison:, prison_record:) }
  end

  class << self
    def get_offenders(offender_numbers, ignore_legal_status: false)
      Array(offender_numbers)
        .map { |offender_number| get_offender(offender_number, ignore_legal_status:) }
        .compact
    end

    def get_community_data(nomis_offender_id)
      community_info = HmppsApi::CommunityApi.get_offender(nomis_offender_id).deep_symbolize_keys
      registrations = HmppsApi::CommunityApi.get_offender_registrations(nomis_offender_id).deep_symbolize_keys.fetch(:registrations, [])

      mappa_registrations = registrations.select do |r|
        r.fetch(:active) && r.key?(:registerLevel) && r.dig(:registerLevel, :code).starts_with?('M')
      end

      enhanced_resourcing = begin
        HmppsApi::CommunityApi.get_latest_resourcing(nomis_offender_id).fetch('enhancedResourcing', true)
      rescue Faraday::ResourceNotFound
        true
      end

      com = community_info.fetch(:offenderManagers).detect { |om| om.fetch(:active) }

      {
        noms_no: nomis_offender_id,
        tier: community_info.fetch(:currentTier),
        crn: community_info.dig(:otherIds, :crn),
        enhanced_resourcing: enhanced_resourcing,
        offender_manager: com.dig(:staff, :unallocated) ? nil : "#{com.dig(:staff, :surname)}, #{com.dig(:staff, :forenames)}",
        team_name: com.dig(:team, :description),
        ldu_code: com.dig(:team, :localDeliveryUnit, :code),
        mappa_levels: mappa_registrations.map { |r| r.dig(:registerLevel, :code).last.to_i },
        active_vlo: registrations.any? { |r| r.fetch(:active) && %w[INVI DASO].include?(r.dig(:type, :code)) }
      }.with_indifferent_access
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
      }).with_indifferent_access
    end

    def get_mappa_details(crn)
      nil_details = { category: nil, level: nil, short_description: nil, review_date: nil, start_date: nil }

      return nil_details if crn.blank?

      details = HmppsApi::ManagePomCasesAndDeliusApi.get_mappa_details(crn)

      {
        category: details['category'],
        level: details['level'],
        short_description: "CAT #{details['category']}/LEVEL #{details['level']}",
        review_date: details['reviewDate'].present? ? Date.parse(details['reviewDate']) : nil,
        start_date: Date.parse(details['startDate'])
      }
    rescue Faraday::ResourceNotFound
      nil_details
    end

    def get_probation_record(offender_no_or_crn)
      result = HmppsApi::ManagePomCasesAndDeliusApi.get_probation_record(offender_no_or_crn).with_indifferent_access

      {
        crn: result[:crn],
        noms_id: result[:nomsId],
        tier: result[:currentTier],
        resourcing: result[:resourcing],
        manager: {
          team: {
            code: result.dig(:manager, :team, :code),
            description: result.dig(:manager, :team, :description),
            local_delivery_unit: {
              code: result.dig(:manager, :team, :localDeliveryUnit, :code),
              description: result.dig(:manager, :team, :localDeliveryUnit, :description),
            },
          },
          code: result.dig(:manager, :code),
          name: {
            forename: result.dig(:manager, :name, :forename),
            middle_name: result.dig(:manager, :name, :middleName),
            surname: result.dig(:manager, :name, :surname),
          },
          email: result.dig(:manager, :email)
        },
        mappa_level: result[:mappaLevel],
        vlo_assigned: result[:vloAssigned]
      }
    rescue Faraday::ResourceNotFound
      nil
    end

  private

    def find_or_create_offenders(nomis_ids)
      Offender.upsert_all(
        nomis_ids.map { |id| { nomis_offender_id: id } },
        unique_by: :nomis_offender_id
      )

      Offender.includes(
        :early_allocations,
        :responsibility,
        :parole_reviews,
        case_information: [:local_delivery_unit]
      ).where(nomis_offender_id: nomis_ids)
    end
  end
end
