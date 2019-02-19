class Override < ApplicationRecord
  validates :nomis_staff_id, presence: { message: 'must be provided' }
  validates :nomis_offender_id, presence: { message: 'must be provided' }
  validates :override_reasons, presence: { message: 'must be provided' }
  validates :more_detail,
    presence: { message: 'must be provided when Other is selected' },
    if: proc { |o|
          o.override_reasons.present? && o.override_reasons.include?('other')
        }
end
