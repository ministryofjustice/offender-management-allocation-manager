# frozen_string_literal: true

class PrisonersController < PrisonsApplicationController
  before_action :ensure_spo_user, except: [:show, :image, :search]

  before_action :load_all_offenders, only: [:allocated, :missing_information, :unallocated, :search]

  def allocated
    retrieve_latest_allocation_details
    load_summary :allocated
  end

  def missing_information
    load_summary :missing_information
  end

  def unallocated
    retrieve_latest_allocation_details
    load_summary :unallocated
  end

  def search
    @q = search_term
    offenders = SearchService.search_for_offenders(@q, @prison.policy_offenders)
    @offenders, @user_allocations = get_slice_for_page(offenders, @current_user.staff_id)
    MetricsService.instance.increment_search_count

    render @current_user.allocations.empty? ? 'search' : 'search_global'
  end

  def review_case_details
    @prisoner = OffenderService.get_offender(params[:prisoner_id])

    return redirect_to '/404' if @prisoner.nil?

    @alerts = @prisoner.active_alert_labels
    @rosh = @prisoner.rosh_summary
    @oasys_assessment = HmppsApi::AssessRisksAndNeedsApi.get_latest_oasys_date(@prisoner.offender_no)

    @allocation = AllocationHistory.find_by(nomis_offender_id: @prisoner.offender_no)

    if @allocation.present?
      @prev_pom_details = AllocationService.pom_terms(@allocation).reverse.find { |t| t[:ended_at].present? } || {}

      if @allocation.active?
        @pom = StaffMember.new(@prison, @allocation.primary_pom_nomis_id)
      end

      if @allocation.secondary_pom_name.present?
        @secondary_pom_name = PrisonOffenderManagerService.fetch_pom_name(@allocation.secondary_pom_nomis_id).titleize
        @secondary_pom_email = PrisonOffenderManagerService.fetch_pom_email(@allocation.secondary_pom_nomis_id)
      end
    end

    @keyworker = HmppsApi::KeyworkerApi.get_keyworker(
      active_prison_id, @prisoner.offender_no
    )

    @mappa_details = @prisoner.mappa_details
    @coworking = params[:coworking].present?
  end

  def show
    @prisoner = OffenderService.get_offender(params[:id])

    return redirect_to '/404' if @prisoner.nil?

    return render 'show_outside_omic_policy' unless @prisoner.inside_omic_policy?

    @tasks = @prisoner.pom_tasks
    @allocation = AllocationHistory.find_by(nomis_offender_id: @prisoner.offender_no)
    @oasys_assessment = HmppsApi::AssessRisksAndNeedsApi.get_latest_oasys_date(@prisoner.offender_no)

    if @allocation.present?
      @primary_pom_name = PrisonOffenderManagerService.fetch_pom_name(@allocation.primary_pom_nomis_id)
          .titleize
    end

    if @allocation.present? && @allocation.secondary_pom_name.present?
      @secondary_pom_name = PrisonOffenderManagerService.fetch_pom_name(@allocation.secondary_pom_nomis_id).titleize
    end

    @keyworker = HmppsApi::KeyworkerApi.get_keyworker(
      active_prison_id, @prisoner.offender_no
    )

    @emails_sent_to_ldu = EmailHistory.sent_within_current_sentence(@prisoner, EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION)
  end

  def image
    prisoner = OffenderService.get_offender(params[:prisoner_id])

    response.headers['Expires'] = 6.months.from_now.httpdate
    send_data prisoner.get_image, type: 'image/jpg', disposition: 'inline'
  end

private

  def load_all_offenders
    @missing_info = @prison.missing_info
    @unallocated = @prison.unallocated
    @allocated = @prison.allocated.map do |offender|
      OffenderWithAllocationPresenter.new(offender, @prison.allocation_for(offender))
    end
  end

  def load_summary(summary_type)
    items = {
      unallocated: @unallocated,
      missing_information: @missing_info,
      allocated: @allocated
    }.fetch(summary_type)

    @offenders = sort_and_paginate(items, default_sort: :last_name)
  end

  def get_slice_for_page(offender_list, user_id)
    offenders = []
    user_allocations = []

    offender_list.map do |offender|
      allocation = @prison.allocation_for(offender)
      if !allocation.nil? && allocation.primary_pom_nomis_id == user_id
        user_allocations.push OffenderWithAllocationPresenter.new(offender, allocation)
      else
        offenders.push OffenderWithAllocationPresenter.new(offender, allocation)
      end
    end

    [paginate_array(offenders), paginate_array(user_allocations)]
  end

  def search_term
    # defaults to an empty string if the key 'q' can't be found
    params.fetch('q', '').strip
  end
end
