# frozen_string_literal: true

class CaseloadHandoversController < PrisonStaffApplicationController
  def index
    offenders = @pom.pending_handover_offenders

    @upcoming_handovers = Kaminari.paginate_array(offenders).page(page)
    @pending_handover_count = @upcoming_handovers.count
    @summary = SummaryService.new(:handovers, @prison)
  end

private
end
