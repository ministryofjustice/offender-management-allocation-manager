require 'health/status_check'

class Health
  def initialize(timeout_in_seconds_per_check: 2, num_retries_per_check: 2)
    @timeout_in_seconds_per_check = timeout_in_seconds_per_check
    @num_retries_per_check = num_retries_per_check
    @checks = []
  end

  def add_check(name:, get_response:, check_response: STATUS_UP_CHECK)
    @checks << StatusCheck.new(
      name:,
      get_response:,
      check_response:,
      num_retries: @num_retries_per_check,
      timeout_in_seconds: @timeout_in_seconds_per_check)

    self
  end

  def reset_checks!
    @checks = []
  end

  def status
    @checks.each_with_object(status: 'UP', components: {}) do |check, results|
      result = check.up?

      results[:components][check.name] = { status: result ? 'UP' : 'DOWN' }
      results[:status] = 'DOWN' unless result
    end
  end

private

  STATUS_UP_CHECK = ->(response) { response['status'] == 'UP' }
end
