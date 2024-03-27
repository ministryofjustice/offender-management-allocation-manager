module Health
  module StatusCheck
    def up?(get_response)
      with_timeout { with_retries(2) { perform(get_response) } }
    end

  private

    def with_timeout(&block)
      Timeout.timeout(2, &block)
    rescue Timeout::Error
      false
    end

    def with_retries(num_retries)
      num_retries.times do
        yield.tap { |response| return true if response }
      rescue StandardError
        # :noop
      end

      false
    end
  end
end
