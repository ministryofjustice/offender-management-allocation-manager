class AuditEvent < ApplicationRecord
  class << self
    def tags(*tags)
      where('lower(ARRAY[?]::text)::text[] <@ tags', tags)
    end
  end
end
