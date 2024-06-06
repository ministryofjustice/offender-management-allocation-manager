# frozen_string_literal: true

# This class calculates the handover dates for offenders and is the authority for these. The dates calculated here are
# pushed to nDelius, for example.
#
# This class has 1 public class method - self.handover(). this returns a CalculatedHandoverDate model. The quirk,
# however, is that the models returned are new, in-memory ones. Each Offender has a saved one already attached to it
# (offender.calculated_handover_date) yet I cannot find any instance where it is used. Instead, we always calculate
# the handover date afresh by calling HandoverDateService::handover.
class HandoverDateService
  def self.handover(mpc_offender)
    unless mpc_offender.inside_omic_policy?
      raise "Offender #{mpc_offender.offender_no} falls outside of OMIC policy - cannot calculate handover dates"
    end

    handover = OffenderHandover.new(mpc_offender)
    handover.as_calculated_handover_date
  end
end
