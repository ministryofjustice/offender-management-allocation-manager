# frozen_string_literal: true

class CaseInformationController < PrisonsApplicationController
  include PrisonerPageNavigation

  before_action :set_prisoner, :set_case_info_or_redirect
  before_action :ensure_new_case_allowed, only: [:new, :create]
  before_action :ensure_editable_manual_entry, :set_back_path, only: [:edit, :update]

  def new
    editable_case_information_fields
    return unless redirect_to_female_missing_info?

    redirect_to(
      new_prison_prisoner_female_missing_info_path(
        active_prison_id, prisoner_id, sort: params[:sort], page: params[:page]
      )
    )
  end

  def edit; end

  def create
    @case_info.assign_attributes(case_information_params_for_create.merge(manual_entry: true))

    if @case_info.save(context: :manual_entry)
      session.delete(complexity_saved_session_key)

      if params.fetch(:commit) == 'Save'
        redirect_to missing_information_prison_prisoners_path(active_prison_id, sort: params[:sort], page: params[:page])
      else
        redirect_to prison_prisoner_review_case_details_path(prison_id: active_prison_id, prisoner_id:)
      end
    else
      render :new
    end
  end

  def update
    @case_info.assign_attributes(case_information_params.merge(manual_entry: true))

    if @case_info.save(context: :manual_entry)
      redirect_to @back_path
    else
      render :edit
    end
  end

private

  def set_prisoner
    @prisoner = OffenderService.get_offender(prisoner_id)
    redirect_to('/404') if @prisoner.nil?
  end

  def set_case_info_or_redirect
    offender = Offender.find_by(nomis_offender_id: prisoner_id)
    return redirect_to('/404') if offender.nil?

    @case_info = offender.case_information || offender.build_case_information
  end

  def prisoner_id
    params.require(:prisoner_id)
  end

  def case_information_params
    params.require(:case_information).permit(:tier, :rosh_level, :enhanced_resourcing).slice(*manual_entry_case_information_fields)
  end

  def case_information_params_for_create
    case_information_params.slice(*editable_case_information_fields)
  end

  def redirect_to_female_missing_info?
    PrisonService.womens_prison?(active_prison_id) && @prisoner.complexity_level.blank? && !complexity_recently_saved?
  end

  def complexity_recently_saved?
    session[complexity_saved_session_key].present?
  end

  def complexity_saved_session_key
    "female_missing_info_complexity_saved_#{prisoner_id}"
  end

  def ensure_new_case_allowed
    return if action_name == 'new' && redirect_to_female_missing_info?
    return unless @case_info.persisted? && @case_info.complete_for_allocation?

    Rails.logger.warn("[#{self.class}] Prisoner #{@prisoner.nomis_offender_id} already has case information, refusing #{action_name}")
    redirect_to('/404')
  end

  def ensure_editable_manual_entry
    return if @case_info.persisted? && @case_info.manual_entry?

    Rails.logger.warn("[#{self.class}] Prisoner #{@prisoner.nomis_offender_id} case information is not editable, refusing #{action_name}")
    redirect_to('/404')
  end

  def set_back_path
    @back_path = prisoner_page_path(prison_id: active_prison_id, prisoner_id:)
    @source_page = prisoner_page_source
  end

  def editable_case_information_fields
    @editable_case_information_fields ||= if @case_info.persisted?
                                            [].tap do |fields|
                                              fields << :tier if @case_info.tier.blank?
                                              fields << :rosh_level if rosh_level_feature_enabled? && @case_info.rosh_level.blank?
                                              fields << :enhanced_resourcing if @case_info.enhanced_resourcing.nil?
                                            end
                                          else
                                            manual_entry_case_information_fields
                                          end
  end

  def manual_entry_case_information_fields
    @manual_entry_case_information_fields ||= %i[tier enhanced_resourcing].tap do |fields|
      fields.insert(1, :rosh_level) if rosh_level_feature_enabled?
    end
  end

  def rosh_level_feature_enabled?
    FeatureFlags.rosh_level.enabled?
  end
end
