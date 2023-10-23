class HmppsApi::ActiveCaseloadApi
  def self.current_user_active_caseload(token)
    response = current_user_all_caseloads(token).detect { |i| i['currentlyActive'] == true }
    return nil if response.nil?

    response.fetch('caseLoadId', nil)
  end

  def self.current_user_all_caseloads(token)
    client(token).get('/api/users/me/caseLoads', cache: false)
  end

  def self.client(token)
    host = Rails.configuration.prison_api_host
    HmppsApi::Client.new(host, user_token: token)
  end
end
