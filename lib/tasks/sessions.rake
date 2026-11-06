# frozen_string_literal: true

namespace :sessions do
  expire_legacy = lambda do |dry_run:|
    cache = Rails.cache
    abort 'Requires the Redis cache-backed session store' unless
      Rails.application.config.session_store == ActionDispatch::Session::CacheStore &&
        cache.is_a?(ActiveSupport::Cache::RedisCacheStore)
    abort 'Namespaced Redis caches are not supported by this task' if cache.options[:namespace].present?

    expiry = Rails.application.config.session_options.fetch(:expire_after).to_i
    abort 'A positive session expiry must be configured' unless expiry.positive?

    spread = 4.hours.to_i
    script = <<~LUA
      if redis.call('TTL', KEYS[1]) == -1 then
        return redis.call('EXPIRE', KEYS[1], ARGV[1])
      end
      return 0
    LUA

    count = 0
    cache.redis.with do |redis|
      redis.scan_each(match: '_session_id:*', count: 1_000).each_slice(500) do |keys|
        results = redis.pipelined do |pipeline|
          keys.each do |key|
            if dry_run
              pipeline.ttl(key)
            else
              pipeline.eval(script, keys: [key], argv: [expiry + rand(0..spread)])
            end
          end
        end

        count += dry_run ? results.count(-1) : results.sum
      end
    end

    puts "task=legacy_session_expiry dry_run=#{dry_run} count=#{count} expiry_seconds=#{expiry} spread_seconds=#{spread}"
  end

  namespace :expire_legacy do
    desc 'Preview legacy redis sessions without a TTL'
    task dry_run: :environment do
      expire_legacy.call(dry_run: true)
    end

    desc 'Apply the configured session expiry plus a spread to legacy redis sessions without a TTL'
    task process: :environment do
      expire_legacy.call(dry_run: false)
    end
  end
end
