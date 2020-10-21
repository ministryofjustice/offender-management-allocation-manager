# frozen_string_literal: true

class DebuggingController < PrisonsApplicationController
  def debugging
    nomis_offender_id = id

    prisoner = OffenderService.get_offender(nomis_offender_id) if nomis_offender_id

    if prisoner.present?
      @offender = OffenderPresenter.new(prisoner)

      @allocation = Allocation.find_by(nomis_offender_id: @offender.offender_no)
      @movements =
        HmppsApi::PrisonApi::MovementApi.movements_for(@offender.offender_no).last
    end
  end

  def prison_info
    @prison_title = PrisonService.name_for(active_prison_id)

    @summary = create_summary
    @filtered_offenders_count = [
      @summary.allocated.count,
      @summary.unallocated.count,
      @summary.pending.count
    ].sum

    @unfiltered_offenders_count = unfiltered_offenders.count
    @filtered = filtered_offenders
  end

private

  def create_summary
    @summary = SummaryService.summary(
      :allocated, @prison
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
    params[:offender_no].present? ? params[:offender_no].strip : params[:offender_no]
  end

  # def offender(offender_no)
  #   return nil if offender_no.blank?
  #
  #   OffenderService.get_offender(offender_no)
  # end
end
