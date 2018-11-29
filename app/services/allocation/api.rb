module Allocation
  class Api
    include Singleton

    class << self
      delegate :status, to: :instance
    end

    def initialize
      host = Rails.configuration.allocation_api_host
      @allocation_api_client = Allocation::Client.new(host)
    end

    def status
      route = '/status'
      @allocation_api_client.get(route)
    end
  end
end
