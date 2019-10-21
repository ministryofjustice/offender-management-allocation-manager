# frozen_string_literal: true

module EarlyAllocationHelper
  def early_allocation_status(early_allocation)
    if early_allocation.present?
      active_status(early_allocation)
    else
      'Not Assessed'
    end
  end

private

  def active_status(early_allocation)
    if early_allocation.eligible?
      'Eligible - Automatic'
    elsif early_allocation.ineligible?
      'Not Eligible'
    elsif early_allocation.community_decision.nil?
      'Waiting for community decision'
    elsif early_allocation.community_decision?
      'Eligible - Discretionary'
    else
      'Not Eligible'
    end
  end
end
