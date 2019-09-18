# frozen_string_literal: true

class DebuggingController < PrisonsApplicationController
  def debugging
    nomis_offender_id = id

    @offender = offender(nomis_offender_id)
    if @offender.present?
      @allocation = AllocationVersion.find_by(nomis_offender_id: @offender.offender_no)
      @movements =
        Nomis::Elite2::MovementApi.movements_for(@offender.offender_no).last
    end
  end

  def prison_info
    @prison_title = PrisonService.name_for(active_prison)

    @summary = create_summary
    @filtered_offenders_count = [
      @summary.allocated_total,
      @summary.unallocated_total,
      @summary.pending_total
    ].sum

    # Make a request for a single offender to get the total number of
    # unfiltered offenders in nomis
    info = Nomis::Elite2::OffenderApi.list(@prison, 1, page_size: 1)
    @unfiltered_offenders_count = info.meta.total_elements

    @filtered = filtered_offenders
  end

private

  def create_summary
    params = SummaryService::SummaryParams.new(
      sort_field: nil,
      sort_direction: nil
    )

    @summary = SummaryService.summary(
      :allocated, active_prison, 0, params
    )
  end

  def filtered_offenders
    unfiltered_offenders = OffenderService.get_unfiltered_offenders_for_prison(
      active_prison
    )

    unfiltered_offenders.group_by { |offender|
      if offender.age < 18
        :under18
      elsif SentenceType.civil?(offender.imprisonment_status)
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
