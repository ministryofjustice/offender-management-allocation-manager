# frozen_string_literal: true

module CommunityApiHelper
  COMMUNITY_API_HOST = Rails.configuration.community_api_host

  def stub_community_set_pom(offender)
    offender_no = offender.fetch(:offenderNo)
    route = "#{COMMUNITY_API_HOST}/secure/offenders/nomsNumber/#{offender_no}/prisonOffenderManager"
    stub_request(:put, route).to_return(status: 200, body: '{}')
  end
end
