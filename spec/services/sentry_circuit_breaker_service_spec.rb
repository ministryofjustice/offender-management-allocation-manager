class FakeRedis
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def set(key, val)
    @data[key] = val
  end

  def get(key)
    @data[key].to_s
  end

  def incr(key)
    @data[key] = (@data[key] || 0) + 1
  end
end

RSpec.describe SentryCircuitBreakerService do
  subject(:result) do
    described_class.check_within_quota(date: check_date)
  end

  before do
    allow(described_class).to receive(:redis_client).and_return(fake_redis)
  end

  let(:fake_redis) do
    FakeRedis.new(redis_data)
  end

  let(:count_key) { SentryCircuitBreakerService::COUNT_KEY }
  let(:reset_key) { SentryCircuitBreakerService::LAST_RESET_KEY }
  let(:warn_key) { SentryCircuitBreakerService::LAST_WARN_KEY }

  context 'when first time called' do
    let(:check_date) { Date.new(2000, 1, 1) }
    let(:redis_data) { {} }

    it 'initialises the count' do
      result
      expect(fake_redis.data).to eq({ count_key => 1 })
    end
  end

  context 'when within monthly quota' do
    let(:check_date) { Date.new(2000, 1, 1) }

    let(:redis_data) do
      { count_key => 0, reset_key => Date.new(1999, 1, 1).to_s }
    end

    it 'increments counter' do
      result
      expect(fake_redis.data[count_key]).to eq(1)
    end

    it 'returns true' do
      expect(result).to eq(true)
    end
  end

  context 'when above monthly quota' do
    let(:request_count) { SentryCircuitBreakerService::MONTHLY_QUOTA + 1 }

    context 'and it is not reset day' do
      let(:check_date) { Date.new(2000, 1, 1) }
      let(:last_warn) { nil }

      let(:redis_data) do
        {
          count_key => request_count,
          reset_key => Date.new(1999, 1, 1).to_s,
          warn_key => last_warn
        }
      end

      it 'increments counter' do
        result
        expect(fake_redis.data[count_key]).to eq(request_count + 1)
      end

      it 'returns false' do
        expect(result).to eq(false)
      end

      context 'when has not logged a warning today' do
        it 'logs a warning' do
          expect(Rails.logger).to receive(:warn)
          result
        end

        it 'sets last warn' do
          result
          expect(fake_redis.data[warn_key]).to eq(check_date.to_s)
        end
      end

      context 'when has already logged a warning today' do
        let(:last_warn) { check_date.to_s }

        it 'does not log a warning' do
          expect(Rails.logger).not_to receive(:warn)
          result
        end
      end
    end

    context 'and it is reset day' do
      let(:check_date) { Date.new(2000, 1, SentryCircuitBreakerService::MONTHLY_RESET_DAY) }

      context 'and the counter has not been reset today' do
        let(:redis_data) do
          { count_key => request_count, reset_key => Date.new(1999, 1, 1).to_s }
        end

        it 'resets the counter' do
          result
          expect(fake_redis.data[count_key]).to eq(1)
        end

        it 'sets last reset to today' do
          result
          expect(fake_redis.data[reset_key]).to eq(check_date.to_s)
        end

        it 'returns true' do
          expect(result).to eq(true)
        end
      end

      context 'and the counter has been reset today' do
        let(:redis_data) do
          { count_key => request_count, reset_key => check_date.to_s }
        end

        it 'does not reset the counter' do
          result
          expect(fake_redis.data[count_key]).to eq(request_count + 1)
        end

        it 'returns false' do
          expect(result).to eq(false)
        end
      end
    end
  end
end
