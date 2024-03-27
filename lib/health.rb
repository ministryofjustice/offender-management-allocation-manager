require 'health/status_check'
require 'health/key_value_check'

module Health
  def self.checks
    @checks ||= []
  end

  def self.reset_checks!
    @checks = []
  end

  def self.add_check(name:, get_response:, check_response: {})
    check = case check_response
            in { key:, value: }
              KeyValueCheck.new(key:, value:)
            in { value: }
              KeyValueCheck.new(value:)
            else
              KeyValueCheck.new(key: 'status', value: 'UP')
            end

    checks << { name:, get_response:, check: }

    self
  end

  def self.status
    checks.each_with_object(status: 'UP', components: {}) do |check_details, results|
      check_details => { name:, get_response:, check: }

      result = check.up?(get_response)

      results[:components][name] = { status: result ? 'UP' : 'DOWN' }
      results[:status] = 'DOWN' unless result
    end
  end
end
