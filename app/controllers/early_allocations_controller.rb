# frozen_string_literal: true

class EarlyAllocationsController < PrisonsApplicationController
  before_action :load_prisoner

  def new
    @early_assignment = EarlyAllocation.new offender_id_from_url
  end

  def create
    @early_assignment = EarlyAllocation.new early_allocation_params.merge(offender_id_from_url)
    if !@early_assignment.stage2_validation?
      stage1
    else
      stage2
    end
  end

  def discretionary
    @early_assignment = EarlyAllocation.new early_allocation_params.merge(offender_id_from_url)
    if @early_assignment.valid?
      render
    else
      render 'why'
    end
  end

private

  def load_prisoner
    @offender = OffenderService.get_offender(params[:prisoner_id])
    @allocation = AllocationVersion.find_by!(offender_id_from_url)
    @pom = PrisonOffenderManagerService.get_pom(@prison, @allocation.primary_pom_nomis_id)
  end

  def stage1
    if @early_assignment.save
      render 'eligible'
    elsif @early_assignment.any_stage1_field_errors?
      render 'new'
    else
      render 'stage2_new'
    end
  end

  def stage2
    if @early_assignment.valid?
      if @early_assignment.ineligible?
        @early_assignment.save!
        render 'ineligible'
      else
        render 'why'
      end
    else
      render 'new'
    end
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
