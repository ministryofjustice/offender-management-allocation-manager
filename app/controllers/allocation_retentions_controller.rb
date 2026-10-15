# frozen_string_literal: true

class AllocationRetentionsController < PrisonsApplicationController
  before_action :ensure_spo_user, :load_review

  def new
    @override = OverrideForm.new
  end

  def create
    @override = OverrideForm.new(override_params)

    if @override.valid?
      AllocationService.retain(
        allocation: @review.allocation,
        override: @override,
        recommended_pom_type: @prisoner.recommended_pom_type,
      )
      redirect_to review_allocations_prison_prisoners_path(@prison),
                  notice: "#{@prisoner.full_name_ordered} still allocated to #{@pom.full_name_ordered}"
    else
      render :new, status: :unprocessable_entity
    end
  end

private

  def override_params
    params.require(:override_form).permit(:more_detail, :suitability_detail, override_reasons: [])
  end

  def load_review
    @prisoner = @prison.allocated.find { it.offender_no == params[:prisoner_id] }
    return redirect_to('/404') unless @prisoner

    @review = SignificantChanges.for(
      [@prisoner], @prison.allocations,
      poms: -> { @prison.get_list_of_poms(include_deleted: true) }
    ).first
    return redirect_to review_allocations_prison_prisoners_path(@prison) unless @review&.any?

    @pom = StaffMember.new(@prison, @review.allocation.primary_pom_nomis_id)
  end
end
