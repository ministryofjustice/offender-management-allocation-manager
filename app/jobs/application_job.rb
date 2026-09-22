class ApplicationJob < ActiveJob::Base
  # Cap sidekiq retries at 20 (~2 day span with exponential backoff)
  # Individual jobs can override with `sidekiq_options retry: N`
  sidekiq_options retry: 20

  # Timeout for all jobs, 1 hour should accommodate even the longest batch operations
  # Prevents hung workers from blocking the queue indefinitely
  sidekiq_options timeout_in_seconds: 3600

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
