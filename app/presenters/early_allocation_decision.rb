# frozen_string_literal: true

class EarlyAllocationDecision
  def initialize(early_allocation)
    @early_allocation = early_allocation
  end

  def prison
    @early_allocation.prison
  end

  def created_at
    @early_allocation.updated_at
  end

  def created_by_name
    "#{@early_allocation.updated_by_lastname}, #{@early_allocation.updated_by_firstname}"
  end

  def to_partial_path
    if @early_allocation.community_decision?
      'ea_decision_eligible'
    else
      'ea_decision_ineligible'
    end
  end
end
