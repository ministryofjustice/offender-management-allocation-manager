# frozen_string_literal: true

module EarlyAllocationHelper
  def early_allocation_status(early_allocation)
    if early_allocation.present?
      active_status(early_allocation)
    else
      'Not assessed'
    end
  end

private

  def active_status(early_allocation)
    if early_allocation.eligible?
      'Eligible'
    elsif early_allocation.ineligible?
      'Not eligible'
    elsif early_allocation.community_decision.nil?
      'Waiting for community decision'
    elsif early_allocation.community_decision?
      'Eligible'
    else
      'Not eligible'
    end
  end
end
