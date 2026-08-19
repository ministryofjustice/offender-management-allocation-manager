# frozen_string_literal: true

# Bulk variant of FetchTierJob used when refreshing tiers across all cases at
# once. Runs on the deferred queue so it never blocks time-sensitive work.
class BulkFetchTierJob < FetchTierJob
  queue_as :deferred
end
