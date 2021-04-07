# frozen_string_literal: true

# This controller handles the edit/update action from the 'Make Allocation page'.
# We do not show the secondary pages that are displayed in the ComplexityController update action
class ComplexityLevelAllocationsController < PrisonsApplicationController
  before_action :load_offender_id

  def edit
    @prisoner = OffenderService.get_offender(@offender_id)
    @complexity = Complexity.new level: @prisoner.complexity_level
  end

  def update
    @prisoner = OffenderService.get_offender(@offender_id)

    @complexity = Complexity.new(complexity_params)
    if @complexity.valid?
      HmppsApi::ComplexityApi.save(@offender_id, level: @complexity.level, username: current_user, reason: @complexity.reason)
      redirect_to prison_prisoner_staff_index_path(@prison.code, @offender_id)
    else
      render :edit
    end
  end

  def complexity_params
    params.require(:complexity).permit(:level, :reason)
  end

  def load_offender_id
    @offender_id = params[:prisoner_id]
  end
end
