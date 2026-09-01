class AuditEvent < ApplicationRecord
  after_commit :log_published_event, on: :create

  class << self
    def publish(**attrs)
      attrs = attrs.stringify_keys
      create!(**attrs)
    end

    def tags(*tags)
      where('lower(ARRAY[?]::text)::text[] <@ tags', tags)
    end
  end

private

  def log_published_event
    Rails.logger.info(
      [
        'event=audit_event_published',
        "nomis_offender_id=#{nomis_offender_id}",
        "audit_event_id=#{id}",
        *tags.map { "tag=#{it}" },
      ].join(',')
    )
  end
end
