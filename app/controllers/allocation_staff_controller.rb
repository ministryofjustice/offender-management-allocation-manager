# frozen_string_literal: true

class AllocationStaffController < PrisonsApplicationController
  before_action :ensure_spo_user
  before_action :load_pom_types
  before_action :load_prisoner_via_prisoner_id

  def index
    @case_info = Offender.find_by!(nomis_offender_id: prisoner_id_from_url).case_information
    @allocation = AllocationHistory.find_by nomis_offender_id: prisoner_id_from_url
    previous_pom_ids = if @allocation
                         @allocation.previously_allocated_poms
                       else
                         []
                       end
    poms = @prison.get_list_of_poms.index_by(&:staff_id)
    @previous_poms = previous_pom_ids.map { |staff_id| poms[staff_id] }.compact
    @current_pom = @prison.get_single_pom(@allocation.primary_pom_nomis_id) if @allocation&.primary_pom_nomis_id
  end

private

  def prisoner_id_from_url
    params.require(:prisoner_id)
  end

  def load_pom_types
    poms = @prison.get_list_of_poms.map { |pom| StaffMember.new(@prison, pom.staff_id) }.sort_by(&:last_name)
    @probation_poms, @prison_poms = poms.partition(&:probation_officer?)
  end

  def load_prisoner_via_prisoner_id
    @prisoner = OffenderService.get_offender(prisoner_id_from_url)
  end
end
