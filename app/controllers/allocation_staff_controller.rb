# frozen_string_literal: true

class AllocationStaffController < PrisonsApplicationController
  MAX_RECENT_POM_HISTORY = 3
  MAX_COMPARISON_SIZE = 4

  before_action :ensure_spo_user
  before_action :load_pom_types
  before_action :load_prisoner_via_prisoner_id
  before_action :store_referrer_in_session, only: [:index]
  before_action :set_referrer

  def index
    previous_pom_ids = allocation ? allocation.previously_allocated_poms : []
    poms = @prison.get_list_of_poms.index_by(&:staff_id)

    @previous_poms = previous_pom_ids.map { |staff_id| poms[staff_id] }.compact
    @current_pom = poms[allocation&.primary_pom_nomis_id]
    @current_coworker = poms[allocation&.secondary_pom_nomis_id]
    @recent_pom_history = AllocationService.pom_terms(allocation).select { |t| t[:ended_at].present? }.reverse.first(MAX_RECENT_POM_HISTORY)
    @coworking = coworking?

    # As primary POM and coworker POM must be different, we filter out
    # ineligible POMs based on currently allocated staff
    filtered_poms = active_poms.reject do |pom|
      [@current_pom&.staff_id, @current_coworker&.staff_id].include?(pom.staff_id)
    end

    sort_dir = @prisoner.recommended_pom_type == RecommendationService::PRISON_POM ? :desc : :asc
    @available_poms = sort_collection(filtered_poms, default_sort: :position, default_direction: sort_dir)
  end

  def check_compare_list
    if params[:pom_ids].nil?
      error_message = 'Choose someone to allocate to or compare workloads'
    elsif params[:pom_ids].size > MAX_COMPARISON_SIZE
      error_message = 'You can only choose up to 4 POMs to compare workloads'
    end

    if error_message
      redirect_to(check_compare_error_route, alert: error_message) and return
    end

    redirect_to check_compare_success_route
  end

  def compare_poms
    @coworking = coworking?

    if allocation
      @current_pom_id = allocation.primary_pom_nomis_id
      @previous_pom_ids = allocation.previously_allocated_poms

      # Make current and previous POMs appear first
      ordered_pom_ids = params[:pom_ids].sort_by do |id|
        if id.to_i == @current_pom_id
          0
        elsif @previous_pom_ids.include?(id.to_i)
          1
        else
          2
        end
      end
    end

    @poms = (ordered_pom_ids || params[:pom_ids]).map { |staff_id| StaffMember.new(@prison, staff_id) }
  end

private

  def prisoner_id_from_url
    params.require(:prisoner_id)
  end

  def allocation
    @allocation ||= AllocationHistory.find_by(nomis_offender_id: prisoner_id_from_url)
  end

  def active_poms
    @prison_poms.select(&:active?) + @probation_poms.select(&:active?)
  end

  def load_pom_types
    poms = @prison.get_list_of_poms.map { |pom| StaffMember.new(@prison, pom.staff_id) }.sort_by(&:full_name_ordered)
    @probation_poms, @prison_poms = poms.partition(&:probation_officer?)
  end

  def load_prisoner_via_prisoner_id
    @prisoner = OffenderService.get_offender(prisoner_id_from_url)
    redirect_to('/404') if @prisoner.nil?
  end

  def coworking?
    params[:coworking].present? && params[:coworking] == 'true'
  end

  def check_compare_success_route
    prison_prisoner_compare_poms_path(
      @prison, @prisoner.offender_no, pom_ids: params[:pom_ids], coworking: coworking?
    )
  end

  def check_compare_error_route
    prison_prisoner_staff_index_path(
      @prison, @prisoner.offender_no, coworking: coworking?
    )
  end
end
