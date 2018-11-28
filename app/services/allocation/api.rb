module Allocation
  class Api
    include Singleton

    class << self
      delegate :get_status, to: :instance
    end

    def initialize
      @allocation_api_client = Allocation::Client.new Rails.configuration.allocation_api_host
    end

    def get_status
      route = '/status'
      @allocation_api_client.get(route)
    end
  end
end
