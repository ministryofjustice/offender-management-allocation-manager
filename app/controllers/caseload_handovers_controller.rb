# frozen_string_literal: true

class CaseloadHandoversController < PrisonStaffApplicationController
  def index
    bucket = Bucket.new([:last_name, :handover_start_date, :responsibility_handover_date,
                         :pom_responsibility, :allocated_com_name, :case_allocation])
    @pom.pending_handover_offenders.each { |o| bucket << o }
    if params['sort']
      sort_params = params['sort'].split.map { |s| s.downcase.to_sym }
      bucket.sort_bucket!(sort_params[0], sort_params[1] || :asc)
    else
      bucket.sort_bucket!(:last_name, :asc)
    end

    @offenders = Kaminari.paginate_array(bucket.to_a).page(page)
    @pending_handover_count = bucket.count
    @prison_total_handovers = SummaryService.new(:handovers, @prison).handovers_total
  end
end
