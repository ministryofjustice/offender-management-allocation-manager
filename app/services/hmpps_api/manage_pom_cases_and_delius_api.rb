module HmppsApi
  class ManagePomCasesAndDeliusApi
    def self.client
      host = Rails.configuration.manage_pom_cases_and_delius_host
      HmppsApi::Client.new(host)
    end

    # https://manage-pom-cases-and-delius-preprod.hmpps.service.justice.gov.uk/swagger-ui/index.html#/probation-record-resource/handle
    def self.get_probation_record(offender_no_or_crn)
      route = "/case-records/#{offender_no_or_crn}"
      client.get(route)
    end

    # https://manage-pom-cases-and-delius-preprod.hmpps.service.justice.gov.uk/swagger-ui/index.html#/mappa-resource/getMappaDetails
    def self.get_mappa_details(crn)
      route = "/case-records/#{crn}/risks/mappa"
      client.get(route)
    end
  end
end
