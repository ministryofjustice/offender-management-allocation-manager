# frozen_string_literal: true

class CaseInformationController < PrisonsApplicationController
  before_action :set_prisoner
  before_action :set_case_info_or_redirect
  before_action :set_referrer
  before_action :store_referrer_in_session, only: [:edit]

  def new; end

  def edit
    unless @case_info.manual_entry?
      Rails.logger.warn("[#{self.class}] Prisoner #{@prisoner.nomis_offender_id} is not marked as manual entry, refusing edit")
      redirect_to('/404')
    end
  end

  def create
    @case_info.assign_attributes(case_information_params.merge(manual_entry: true))

    if @case_info.save(context: :manual_entry)
      if params.fetch(:commit) == 'Save'
        redirect_to missing_information_prison_prisoners_path(active_prison_id, sort: params[:sort], page: params[:page])
      else
        redirect_to prison_prisoner_staff_index_path(active_prison_id, nomis_offender_id)
      end
    else
      render :new
    end
  end

  def update
    @case_info.assign_attributes(case_information_params.merge(manual_entry: true))

    if @case_info.save(context: :manual_entry)
      redirect_to referrer
    else
      render :edit
    end
  end

private

  def set_prisoner
    @prisoner = OffenderService.get_offender(nomis_offender_id)
  end

  def set_case_info_or_redirect
    offender = Offender.find_by(nomis_offender_id:).tap do
      redirect_to('/404') if it.nil?
    end

    @case_info = offender.case_information || offender.build_case_information
  end

  def nomis_offender_id
    action_name.in?(%w[new edit]) ? params.require(:prisoner_id) : case_information_params[:nomis_offender_id]
  end

  def case_information_params
    params.require(:case_information).permit(:nomis_offender_id, :tier, :enhanced_resourcing)
  end
end
