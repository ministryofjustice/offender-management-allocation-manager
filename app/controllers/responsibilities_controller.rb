# frozen_string_literal: true

class ResponsibilitiesController < PrisonsApplicationController
  include PrisonerPageNavigation

  before_action :ensure_spo_user
  before_action :load_offender_from_url, only: [:new, :confirm_removal, :destroy]
  before_action :load_offender_from_responsibility_params, only: [:confirm, :create]
  before_action :set_navigation_context
  before_action :check_existing_responsibility, only: [:new, :confirm]

  def new
    if @offender.ldu_email_address.present?
      @responsibility = Responsibility.new(nomis_offender_id:)
    else
      render 'error'
    end
  end

  def confirm
    @responsibility = Responsibility.new(responsibility_params)

    if @responsibility.valid?
      @ldu_email_address = @offender.ldu_email_address
    else
      render 'new'
    end
  end

  def create
    emails = [@current_user.email_address, @offender.ldu_email_address].compact_blank

    @responsibility = Responsibility.find_or_initialize_by(nomis_offender_id:)

    # Treat repeated submits as a no-op so we don't create duplicate overrides or emails.
    return redirect_back_to_origin unless @responsibility.new_record?

    @responsibility.assign_attributes(responsibility_params.slice(:reason, :reason_text, :value))
    @responsibility.save!

    # GovUk notify can only deliver to 1 address at a time.
    emails.each do |email|
      PomMailer.with(
        message: responsibility_params[:message],
        prisoner_number: @responsibility.nomis_offender_id,
        prisoner_name: @offender.full_name,
        prison_name: @prison.name,
        email: email
      ).responsibility_override.deliver_later
    end

    redirect_back_to_origin
  rescue ActiveRecord::RecordInvalid
    @responsibility = Responsibility.find_by(nomis_offender_id:)
    raise unless @responsibility

    redirect_back_to_origin
  end

  def confirm_removal
    @responsibility = RemoveResponsibilityForm.new(nomis_offender_id:)
    @ldu_email_address = @offender.ldu_email_address
  end

  def destroy
    @responsibility = RemoveResponsibilityForm.new(responsibility_params)

    if @responsibility.valid?
      Responsibility.find_by!(nomis_offender_id:).destroy!

      emails = [@current_user.email_address, @offender.ldu_email_address]
      allocation = AllocationHistory.find_by(nomis_offender_id:)

      if allocation&.active?
        pom_email = safe_primary_pom_email_for(allocation)
        [*emails, pom_email].compact_blank.uniq.each do |email|
          ResponsibilityMailer.with(email: email,
                                    pom_name: allocation.primary_pom_name,
                                    pom_email: pom_email,
                                    prisoner_name: @offender.full_name,
                                    prisoner_number: nomis_offender_id,
                                    prison_name: @prison.name,
                                    notes: @responsibility.reason_text).responsibility_to_custody_with_pom.deliver_later
        end
      else
        emails.compact_blank.each do |email|
          ResponsibilityMailer.with(email: email,
                                    prisoner_name: @offender.full_name,
                                    prisoner_number: nomis_offender_id,
                                    prison_name: @prison.name,
                                    notes: @responsibility.reason_text).responsibility_to_custody.deliver_later
        end
      end
      redirect_back_to_origin
    else
      render :confirm_removal
    end
  end

private

  def check_existing_responsibility
    render 'responsibilities/presence_error' if Responsibility.exists?(nomis_offender_id:)
  end

  def redirect_back_to_origin
    redirect_to prisoner_page_path(prison_id: @prison.code, prisoner_id: nomis_offender_id)
  end

  def nomis_offender_id_from_url
    params.fetch(:nomis_offender_id)
  end

  def load_offender_from_url
    @offender = get_offender_or_404(nomis_offender_id_from_url)
  end

  def load_offender_from_responsibility_params
    offender_id = responsibility_params.fetch(:nomis_offender_id)
    @offender = get_offender_or_404(offender_id)
  end

  def nomis_offender_id
    @offender.offender_no
  end

  def set_navigation_context
    @back_path = prisoner_page_path(prison_id: @prison.code, prisoner_id: nomis_offender_id)
    @source_page = prisoner_page_source
  end

  def responsibility_params
    params
      .require(:responsibility)
      .permit(:nomis_offender_id, :reason, :reason_text, :message)
      .merge(value: Responsibility::PROBATION)
  end

  def safe_primary_pom_email_for(allocation)
    HmppsApi::NomisUserRolesApi.email_address(allocation.primary_pom_nomis_id)
  rescue StandardError => e
    Rails.logger.error(
      'event=responsibility_removal_pom_email_lookup_failed,' \
      "nomis_offender_id=#{nomis_offender_id}," \
      "primary_pom_nomis_id=#{allocation.primary_pom_nomis_id}|#{e.message}"
    )
    nil
  end
end
