# frozen_string_literal: true

class DebuggingController < PrisonsApplicationController
  def debugging
    nomis_offender_id = id

    @offender = offender(nomis_offender_id)
    if @offender.present?
      @offender = OffenderPresenter.new(@offender, nil)
      @allocation = Allocation.find_by(nomis_offender_id: @offender.offender_no)
      @movements =
        Nomis::Elite2::MovementApi.movements_for(@offender.offender_no).last
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
    params = SummaryService::SummaryParams.new(
      sort_field: nil,
      sort_direction: nil
    )

    @summary = SummaryService.summary(
      :allocated, @prison, params
    )
  end

  def unfiltered_offenders
    @unfiltered_offenders ||= @prison.unfiltered_offenders
  end

  def filtered_offenders
    @unfiltered_offenders.group_by { |offender|
      if offender.age < 18
        :under18
      elsif offender.civil_sentence?
        :civil
      elsif offender.sentenced? == false
        :unsentenced
      end
    }.except!(nil)
  end

  def id
    params[:offender_no]
  end

  def offender(offender_no)
    return nil if offender_no.blank?

    OffenderService.get_offender(offender_no)
  end
end
