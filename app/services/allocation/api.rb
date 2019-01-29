module Allocation
  class Api
    include Singleton

    class << self
      delegate :status, to: :instance
      delegate :get_allocation_data, to: :instance
      delegate :allocate, to: :instance
    end

    def initialize
      host = Rails.configuration.allocation_api_host
      @allocation_api_client = Allocation::Client.new(host)
    end

    def status
      route = '/status'
      @allocation_api_client.get(route)
    end

    def get_allocation_data(staff_ids)
      staff_ids.each_with_object({}) do |id, hash|
        hash[id] = FakeAllocationRecord.generate(id)
      end
    end

    def allocate(allocation_params)
      route = '/allocate'
      @allocation_api_client.post(route, params: allocation_params)
    end
  end
end
