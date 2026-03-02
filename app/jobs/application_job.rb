class ApplicationJob < ActiveJob::Base
  # Cap sidekiq retries at 20 (~2 day span with exponential backoff)
  # Individual jobs can override with `sidekiq_options retry: N`
  sidekiq_options retry: 20

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
