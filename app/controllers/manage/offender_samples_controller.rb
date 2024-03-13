class Manage::OffenderSamplesController < PrisonsApplicationController
  before_action :ensure_admin_user

  def index
    @form = OffenderSampleForm.new(offender_samples_params)

    if @form.criteria.present?
      @results = OffenderSampleService.new(criteria: @form.criteria, prison_code: @prison.code).results
    end
  end

private

  def offender_samples_params
    params.fetch(:manage_offender_samples_controller_offender_sample_form, {}).permit(criteria: [])
  end

  class OffenderSampleForm
    include ActiveModel::Model
    attr_writer :criteria

    def criteria
      Array(@criteria).compact.map(&:to_sym)
    end
  end
end
