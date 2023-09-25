module HmppsApi
  class ManagePomCasesAndDeliusApi
    def self.client
      host = Rails.configuration.manage_pom_cases_and_delius_host
      HmppsApi::Client.new(host)
    end

    def self.get_probation_record(offender_no_or_crn)
      route = "/case-records/#{offender_no_or_crn}"
      client.get(route)
    end
  end
end
