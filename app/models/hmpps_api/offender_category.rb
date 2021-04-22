# frozen_string_literal: true

module HmppsApi
  class OffenderCategory
    attr_reader :code,
                :label,
                :active_since

    def initialize(payload)
      # Category code – e.g. "A", "B", "C", etc.
      @code = payload.fetch('classificationCode')

      # Human-readable name for the category – e.g. "Cat A", "Female Open", etc.
      @label = payload.fetch('classification')

      # Date the offender's category assessment was approved
      # This denotes the date it became 'active' as the offender's category
      @active_since = payload.fetch('approvalDate').to_date
    end
  end
end
