module Allocation
  class Api
    include Singleton

    class << self
      delegate :status, to: :instance
      delegate :get_allocation_data, to: :instance
      delegate :get_active_allocations, to: :instance
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

    def get_active_allocations(offender_ids)
      route = '/allocation/active'
      @allocation_api_client.post(route, offender_ids)
    end

    def allocate(params)
      route = '/allocation'
      @allocation_api_client.post(route, allocation: params)
    end
  end
end
