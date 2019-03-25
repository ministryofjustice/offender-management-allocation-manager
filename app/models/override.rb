class Override < ApplicationRecord
  validates :nomis_staff_id, presence: {
    message: 'NOMIS Staff ID is required'
  }
  validates :nomis_offender_id, presence: {
    message: 'NOMIS Offender ID is required'
  }
  validates :override_reasons, presence: {
    message: 'Select one or more reasons for not accepting the recommendation'
  }
  validates :more_detail,
    presence: { message:
      'Please provide extra detail when Other is selected'
    },
    if: proc { |o|
          o.override_reasons.present? && o.override_reasons.include?('other')
        }
end
