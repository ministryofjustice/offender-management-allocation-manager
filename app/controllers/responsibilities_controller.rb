# frozen_string_literal: true

class ResponsibilitiesController < PrisonsApplicationController
  def new
    if ldu_email_address(params[:nomis_offender_id])
      @responsibility = Responsibility.new nomis_offender_id: params[:nomis_offender_id]
    else
      render 'error'
    end
  end

  def confirm
    @responsibility = Responsibility.new responsibility_params
    if @responsibility.valid?
      @ldu_email_address = ldu_email_address(@responsibility.nomis_offender_id)
    else
      render 'new'
    end
  end

  def create
    @responsibility = Responsibility.create! responsibility_params

    me = Nomis::Elite2::UserApi.user_details(current_user).email_address.try(:first)

    emails = [me, ldu_email_address(@responsibility.nomis_offender_id)].compact

    # GovUk notify can only deliver to 1 address at a time.
    emails.each do |email|
      PomMailer.responsibility_override(
        message: params[:message],
        prisoner_number: @responsibility.nomis_offender_id,
        prisoner_name: OffenderService.get_offender(@responsibility.nomis_offender_id).full_name,
        prison_name: PrisonService.name_for(@prison.code),
        email: email
      ).deliver_later
    end

    redirect_to prison_allocation_path(@prison.code, @responsibility.nomis_offender_id)
  end

private

  def ldu_email_address(nomis_offender_id)
    @ldu_email_address ||= CaseInformation.
      find_by(nomis_offender_id: nomis_offender_id).
      try(:local_divisional_unit).
      try(:email_address)
  end

  def responsibility_params
    params.
      require(:responsibility).
      permit(:nomis_offender_id, :reason, :reason_text).
      merge(value: Responsibility::PROBATION)
  end
end
