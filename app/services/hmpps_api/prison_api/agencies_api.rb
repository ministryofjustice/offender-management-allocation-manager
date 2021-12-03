module HmppsApi
  module PrisonApi
    class AgenciesApi
      extend PrisonApiClient
      HOSPITAL_AGENCY_TYPE = 'HSHOSP'.freeze
      def self.agencies_by_type(type)
        route = "/agencies/type/#{type}"
        data = client.get(route, cache: true)
        data.map { |agency|
          { agency_type: agency['agencyId'], description: agency['description'], active: (!!agency['active']) }
        }
      end

      def self.agency_ids_by_type(type)
        route = "/agencies/type/#{type}"
        data = client.get(route, cache: true)
        data.map { |agency| agency['agencyId'] }
      end
    end
  end
end
