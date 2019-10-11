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
      'Eligible'
    elsif early_allocation.ineligible?
      'Not Eligible'
    else
      'Waiting for community decision'
    end
  end
end
