# Gets all the handover cases assigned to a POM in various stages of their lifecycle.
#
# NOTE: methods that return each group will return a tuple of AllocatedOffender and CalculatedHandoverDate.
#
# Why do we return a tuple of AllocatedOffender and CalculatedHandoverDate instead of just letting the user use
# AllocatedOffender#handover? AllocatedOffender#handover does all kinds of checks before it returns the handover
# information. These are a waste as we already know if we need to return a CalculatedHandoverDate or not. Also those
# checks are very confusing and the current author does not understand them. Changing the original logic is dangerous
# and time consuming as it is used to publish handover dates to NDelius.
#
# We bypass having to worry about existing plumbing by just finding the CalculatedHandoverDate from the DB for the POM,
# grouping it into the various categories, and returning it directly with the AllocatedOffender.
class HandoverCasesList
  def initialize(staff_member)
    @staff_member = staff_member
  end

  def counts
    # TODO
  end

  def upcoming
    []
  end

  def in_progress
    []
  end

  def overdue_tasks
    []
  end

  def com_allocation_overdue
    []
  end
end
