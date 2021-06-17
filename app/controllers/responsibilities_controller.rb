# frozen_string_literal: true

class ResponsibilitiesController < PrisonsApplicationController
  before_action :load_offender_from_url, only: [:new, :confirm_removal, :destroy]
  before_action :load_offender_from_responsibility_params, only: [:confirm, :create]

  def new
    if @offender.ldu_email_address.present?
      @responsibility = Responsibility.new nomis_offender_id: nomis_offender_id_from_url
    else
      render 'error'
    end
  end

  def confirm
    @responsibility = Responsibility.new responsibility_params
    if @responsibility.valid?
      @ldu_email_address = @offender.ldu_email_address
    else
      render 'new'
    end
  end

  def create
    @responsibility = Responsibility.create! responsibility_params

    me = HmppsApi::PrisonApi::UserApi.user_details(current_user).email_address.try(:first)

    emails = [me, @offender.ldu_email_address].compact

    # GovUk notify can only deliver to 1 address at a time.
    emails.each do |email|
      PomMailer.responsibility_override(
        message: params[:message],
        prisoner_number: @responsibility.nomis_offender_id,
        prisoner_name: @offender.full_name,
        prison_name: @prison.name,
        email: email
      ).deliver_later
    end

    allocation = AllocationHistory.find_by(nomis_offender_id: @responsibility.nomis_offender_id, prison: @prison.code)
    if allocation.try(:active?)
      redirect_to prison_prisoner_allocation_path(@prison.code, @responsibility.nomis_offender_id)
    else
      redirect_to prison_prisoner_staff_index_path(@prison.code, @responsibility.nomis_offender_id)
    end
  end

  def confirm_removal
    @responsibility = RemoveResponsibilityForm.new nomis_offender_id: nomis_offender_id_from_url
    @ldu_email_address = @offender.ldu_email_address
  end

  def destroy
    @responsibility = RemoveResponsibilityForm.new(responsibility_params)
    @ldu_email_address = @offender.ldu_email_address

    allocation = AllocationHistory.find_by(nomis_offender_id: nomis_offender_id_from_url)

    emails = [@current_user.email_address, @ldu_email_address]

    if @responsibility.valid?
      Responsibility.find_by!(nomis_offender_id: nomis_offender_id_from_url).destroy

      if allocation && allocation.active?
        pom_email = HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(allocation.primary_pom_nomis_id).first
        emails << pom_email
        ResponsibilityMailer.responsibility_to_custody_with_pom(emails: emails.compact,
                                                                       pom_name: allocation.primary_pom_name,
                                                                       pom_email: pom_email,
                                                                       prisoner_name: @offender.full_name,
                                                                       prisoner_number: nomis_offender_id_from_url,
                                                                       prison_name: @prison.name,
                                                                       notes: @responsibility.reason_text).deliver_later
      else
        ResponsibilityMailer.responsibility_to_custody(emails: emails.compact,
                                                       prisoner_name: @offender.full_name,
                                                       prisoner_number: nomis_offender_id_from_url,
                                                       prison_name: @prison.name,
                                                       notes: @responsibility.reason_text).deliver_later
      end

      redirect_to prison_prisoner_staff_index_path(@prison.code, nomis_offender_id_from_url)
    else
      render :confirm_removal
    end
  end

private

  def nomis_offender_id_from_url
    params.fetch(:nomis_offender_id)
  end

  def load_offender_from_url
    @offender = OffenderService.get_offender(nomis_offender_id_from_url)
  end

  def load_offender_from_responsibility_params
    offender_id = responsibility_params.fetch(:nomis_offender_id)
    @offender = OffenderService.get_offender(offender_id)
  end

  def responsibility_params
    params.
      require(:responsibility).
      permit(:nomis_offender_id, :reason, :reason_text).
      merge(value: Responsibility::PROBATION)
  end
end
