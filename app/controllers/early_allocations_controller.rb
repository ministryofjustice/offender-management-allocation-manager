# frozen_string_literal: true

class EarlyAllocationsController < PrisonsApplicationController
  before_action :load_prisoner

  def new
    @early_assignment = EarlyAllocation.new offender_id_from_url
  end

  def create
    @early_assignment = EarlyAllocation.new early_allocation_params.merge(offender_id_from_url)
    if @early_assignment.save
      if @early_assignment.eligible?
        render 'eligible'
      else
        render 'ineligible'
      end
    else
      @early_assignment.errors.delete(:stage2_validation)
      render create_error_page
    end
  end

  def discretionary
    @early_assignment = EarlyAllocation.new early_allocation_params.merge(offender_id_from_url)
    if @early_assignment.valid?
      render
    else
      render 'stage3'
    end
  end

private

  def create_error_page
    if !@early_assignment.stage2_validation?
      stage1_error_page
    else
      stage2_error_page
    end
  end

  def stage1_error_page
    if @early_assignment.any_stage1_field_errors?
      'new'
    else
      'stage2_new'
    end
  end

  def stage2_error_page
    if @early_assignment.any_stage2_field_errors?
      'stage2_new'
    else
      'stage3'
    end
  end

  def load_prisoner
    @offender = OffenderService.get_offender(params[:prisoner_id])
    @allocation = AllocationVersion.find_by!(offender_id_from_url)
    @pom = PrisonOffenderManagerService.get_pom(@prison, @allocation.primary_pom_nomis_id)
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
