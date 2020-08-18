# frozen_string_literal: true

class DebuggingController < PrisonsApplicationController
  before_action :ensure_admin_user

  def debugging
    nomis_offender_id = id

    prisoner = OffenderService.get_offender(nomis_offender_id) if nomis_offender_id.present?

    if prisoner.present?
      @offender = prisoner

      @allocation = Allocation.find_by(nomis_offender_id: @offender.offender_no)
      @movements =
        HmppsApi::PrisonApi::MovementApi.movements_for(@offender.offender_no).last
    end
  end

  def prison_info
    @prison_title = PrisonService.name_for(active_prison_id)

    @summary = create_summary
    @filtered_offenders_count = [
      @summary.allocated_total,
      @summary.unallocated_total,
      @summary.pending_total
    ].sum

    @unfiltered_offenders_count = unfiltered_offenders.count
    @filtered = filtered_offenders
  end

private

  def create_summary
    @summary = SummaryService.new(
      :allocated, @prison
    )
  end

  def unfiltered_offenders
    @unfiltered_offenders ||= @prison.unfiltered_offenders
  end

  def filtered_offenders
    @unfiltered_offenders.group_by { |offender|
      if !offender.over_18?
        :under18
      elsif offender.civil_sentence?
        # POM-778: just not covered by tests
        #:nocov:
        :civil
        #:nocov:
      elsif offender.sentenced? == false
        :unsentenced
      end
    }.except!(nil)
  end

  def id
    params[:offender_no].present? ? params[:offender_no].strip : params[:offender_no]
  end
end
