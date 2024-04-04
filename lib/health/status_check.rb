class Health
  class StatusCheck
    attr_reader :name

    def initialize(name:, check_response:, get_response:, num_retries: 2, timeout_in_seconds: 2)
      @name = name
      @check_response = check_response
      @get_response = get_response
      @num_tries = num_retries + 1
      @timeout_in_seconds = timeout_in_seconds
    end

    def up?
      with_timeout do
        with_retries do
          @check_response.call(@get_response.call)
        end
      end
    end

  private

    def with_timeout(&block)
      Timeout.timeout(@timeout_in_seconds, &block)
    rescue Timeout::Error
      false
    end

    def with_retries
      @num_tries.times do
        yield.tap { |response| return true if response }
      rescue StandardError
        # :noop
      end

      false
    end
  end
end
