class AuditEvent < ApplicationRecord
  class << self
    def publish(**attrs)
      attrs = attrs.stringify_keys
      attrs['published_at'] ||= Time.zone.now.utc
      record = create!(**attrs)

      system_log = [
        'event=audit_event_published',
        "nomis_offender_id=#{record.nomis_offender_id}",
        "audit_event_id=#{record.id}",
        *record.tags.map { |t| "tag=#{t}" },
      ].join(',')
      Rails.logger.info system_log

      record
    end

    def tags(*tags)
      where('lower(ARRAY[?]::text)::text[] <@ tags', tags)
    end
  end
end
