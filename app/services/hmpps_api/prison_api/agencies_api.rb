module HmppsApi
  module PrisonApi
    class AgenciesApi
      extend PrisonApiClient
      BASE_PATH = '/agencies/type'.freeze
      HOSPITAL_AGENCY_TYPE = 'HSHOSP'.freeze
      def self.agencies_by_type(type)
        data = client.get("#{BASE_PATH}/#{type}", cache: true)
        data.map do |agency|
          { agency_type: agency['agencyId'], description: agency['description'], active: agency['active'] }
        end
      end

      def self.agency_ids_by_type(type)
        data = client.get("#{BASE_PATH}/#{type}", cache: true)
        data.map { |agency| agency['agencyId'] }
      end
    end
  end
end
