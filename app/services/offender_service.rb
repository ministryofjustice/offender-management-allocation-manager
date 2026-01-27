# frozen_string_literal: true

class OffenderService
  class << self
    def get_offender(offender_no, *args)
      prison_record = HmppsApi::PrisonApi::OffenderApi.get_offender(offender_no, *args)
      return unless prison_record

      prison = Prison.find_by(code: prison_record.prison_id)
      return unless prison

      offender = Offender.find_or_create_by(nomis_offender_id: offender_no)
      MpcOffender.new(prison:, offender:, prison_record:)
    end

    def get_offenders_in_prison(prison, *args)
      prison_records = HmppsApi::PrisonApi::OffenderApi
                         .get_offenders_in_prison(prison.code, *args)
                         .index_by(&:offender_no)

      offenders = find_or_create_offenders(prison_records.keys)
      offenders.map do |offender|
        MpcOffender.new(
          prison:,
          offender:,
          prison_record: prison_records.fetch(offender.nomis_offender_id)
        )
      end
    end

    def get_offenders(offender_numbers, *args)
      Array(offender_numbers)
        .map { |offender_number| get_offender(offender_number, *args) }
        .compact
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
