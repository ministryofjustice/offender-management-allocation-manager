# frozen_string_literal: true

module Timeline
  class EarlyAllocationDecision < BaseHistoryPresenter
    def initialize(early_allocation)
      super()
      @early_allocation = early_allocation
    end

    def created_at
      @early_allocation.updated_at
    end

    def created_by_name
      full_name(@early_allocation.updated_by_firstname, @early_allocation.updated_by_lastname)
    end

    def to_partial_path
      "case_history/early_allocation/#{partial_name}"
    end

  private

    def partial_name
      if @early_allocation.community_decision?
        'decision_eligible'
      else
        'decision_ineligible'
      end
    end
  end
end
