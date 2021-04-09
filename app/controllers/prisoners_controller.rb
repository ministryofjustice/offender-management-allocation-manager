# frozen_string_literal: true

class PrisonersController < PrisonsApplicationController
  def search
    @q = search_term
    offenders = SearchService.search_for_offenders(@q, @prison.offenders)
    @offenders = get_slice_for_page(offenders)

    MetricsService.instance.increment_search_count
  end

  def show
    @prisoner = OffenderService.get_offender(params[:id])
    @tasks = PomTasks.new.for_offender(@prisoner)
    @allocation = Allocation.find_by(nomis_offender_id: @prisoner.offender_no)

    if @allocation.present?
      @primary_pom_name = helpers.fetch_pom_name(@allocation.primary_pom_nomis_id).
          titleize
    end

    if @allocation.present? && @allocation.secondary_pom_name.present?
      @secondary_pom_name = helpers.fetch_pom_name(@allocation.secondary_pom_nomis_id).titleize
    end

    @keyworker = HmppsApi::KeyworkerApi.get_keyworker(
      active_prison_id, @prisoner.offender_no
    )

    @case_info = CaseInformation.includes(:early_allocations).find_by(nomis_offender_id: params[:id])
    @emails_sent_to_ldu = EmailHistory.sent_within_current_sentence(@prisoner, EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION)
  end

  def image
    @prisoner = OffenderService.get_offender(params[:prisoner_id])
    image_data = HmppsApi::PrisonApi::OffenderApi.get_image(@prisoner.booking_id)

    response.headers['Expires'] = 6.months.from_now.httpdate
    send_data image_data, type: 'image/jpg', disposition: 'inline'
  end

private

  def get_slice_for_page(offenders)
    slice = Kaminari.paginate_array(offenders).page(page)

    # At this point offenders contains ALL of the offenders at the prison that
    # match the search term, slice is the current page worth of offenders.
    # We will only show PAGE_SIZE at a time, so there is no need
    # to get the allocated POM name for offenders, we will just get them
    # for the much smaller slice.
    set_allocated_pom_names(slice, active_prison_id)
  end

  def page
    params.fetch('page', 1).to_i
  end

  def search_term
    # defaults to an empty string if the key 'q' can't be found
    params.fetch('q', '').strip
  end

  # Takes a list of OffenderSummary or Offender objects, and returns them with their
  # allocated POM name set in :allocated_pom_name.
  def set_allocated_pom_names(offenders, prison_id)
    pom_names = PrisonOffenderManagerService.get_pom_names(prison_id)
    nomis_offender_ids = offenders.map(&:offender_no)
    offender_to_staff_hash = Allocation.
      where(nomis_offender_id: nomis_offender_ids).
      map { |a|
        [
          a.nomis_offender_id,
          {
            pom_name: pom_names[a.primary_pom_nomis_id],
            allocation_date: (a.primary_pom_allocated_at || a.updated_at)&.to_date
          }
        ]
      }.to_h

    offenders.each do |offender|
      if offender_to_staff_hash.key?(offender.offender_no)
        offender.allocated_pom_name = offender_to_staff_hash[offender.offender_no][:pom_name]
        offender.allocation_date = offender_to_staff_hash[offender.offender_no][:allocation_date]
      end
    end
    offenders
  end
end
