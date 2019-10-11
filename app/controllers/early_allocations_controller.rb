# frozen_string_literal: true

class EarlyAllocationsController < PrisonsApplicationController
  before_action :load_prisoner

  def new
    @early_assignment = EarlyAllocation.new offender_id_from_url
    case_info = CaseInformation.find_by offender_id_from_url
    if case_info.local_divisional_unit.try(:email_address)
      render
    else
      render 'dead_end'
    end
  end

  def create
    @early_assignment = EarlyAllocation.new early_allocation_params.merge(offender_id_from_url)
    if @early_assignment.save
      send_email
      if @early_assignment.eligible?
        render 'eligible'
      else
        render 'ineligible'
      end
    else
      @early_assignment.errors.delete(:stage2_validation)
      render create_error_page 'new'
    end
  end

  # edit results in all the user-facing fields being cleared
  def edit
    @early_assignment = EarlyAllocation.find_by!(offender_id_from_url)
    @early_assignment.clear
  end

  def update
    @early_assignment = EarlyAllocation.find_by(offender_id_from_url)
    if @early_assignment.update(early_allocation_params)
      render create_error_page 'edit'
    else
      render 'edit'
    end
  end

  # record a community decision (changing 'maybe' into a yes or a no)
  def community_decision
    @early_assignment = EarlyAllocation.find_by!(offender_id_from_url)
  end

  def record_community_decision
    @early_assignment = EarlyAllocation.find_by!(offender_id_from_url)

    if @early_assignment.update(community_decision_params)
      redirect_to prison_prisoner_path(@prison, @early_assignment.nomis_offender_id)
    else
      render 'edit'
    end
  end

  def discretionary
    @early_assignment = EarlyAllocation.new early_allocation_params.merge(offender_id_from_url)
    if @early_assignment.save
      send_email
      render
    else
      render 'stage3'
    end
  end

  def show
    @early_assignment = EarlyAllocation.find_by!(offender_id_from_url)

    respond_to do |format|
      format.pdf {
        # disposition 'attachment' is the default for send_data
        send_data pdf_as_string
      }
    end
  end

private

  def load_prisoner
    @offender = OffenderService.get_offender(params[:prisoner_id])
    @allocation = AllocationVersion.find_by!(offender_id_from_url)
    @pom = PrisonOffenderManagerService.get_pom(@prison, @allocation.primary_pom_nomis_id)
  end

  def pdf_as_string
    view_context.render_early_alloc_pdf(early_assignment: @early_assignment,
                                        offender: @offender,
                                        pom: @pom,
                                        allocation: @allocation).render
  end

  def send_email
    PomMailer.early_allocation_email(email: @offender.ldu.email_address,
                                     prisoner_name: @offender.full_name,
                                     prisoner_number: @offender.offender_no,
                                     pom_name: @allocation.primary_pom_name,
                                     pom_email: @pom.emails.first,
                                     prison_name: PrisonService.name_for(@prison),
                                     pdf: pdf_as_string).deliver_later
  end

  def create_error_page(prefix)
    if !@early_assignment.stage2_validation?
      stage1_error_page prefix
    else
      stage2_error_page prefix
    end
  end

  def stage1_error_page(prefix)
    if @early_assignment.any_stage1_field_errors?
      prefix
    else
      "stage2_#{prefix}"
    end
  end

  def stage2_error_page(prefix)
    if @early_assignment.any_stage2_field_errors?
      "stage2_#{prefix}"
    else
      'stage3'
    end
  end

  def community_decision_params
    params.fetch(:early_allocation, {}).permit(:community_decision).merge(recording_community_decision: true)
  end

  def early_allocation_params
    params.require(:early_allocation).
      permit(EarlyAllocation::STAGE1_BOOLEAN_FIELDS +
                EarlyAllocation::ALL_STAGE2_FIELDS +
                [:oasys_risk_assessment_date_dd,
                 :oasys_risk_assessment_date_mm,
                 :oasys_risk_assessment_date_yyyy,
                 :oasys_risk_assessment_date,
                 :stage2_validation,
                 :stage3_validation,
                 :reason,
                 :approved])
  end

  def offender_id_from_url
    { nomis_offender_id: params[:prisoner_id] }
  end
end
