module Events
  class OffenderEvent < ApplicationRecord
    validates :nomis_offender_id, :happened_at, :type, :triggered_by, presence: true
    enum triggered_by: { user: 'user', system: 'system' }, _prefix: true
    validates :triggered_by_nomis_username, presence: true, if: :triggered_by_user?

    # Only allow new records to be written – don't allow update or delete
    def readonly?
      persisted?
    end
  end
end
