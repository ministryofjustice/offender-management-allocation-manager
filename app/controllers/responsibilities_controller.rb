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

  # rubocop:disable Metrics/LineLength
  def create
    @responsibility = Responsibility.create! responsibility_params

    me = PrisonOffenderManagerService.get_signed_in_pom_details(current_user, @prison).emails.try(:first)

    emails = [me, ldu_email_address(@responsibility.nomis_offender_id)].compact

    unless emails.empty?
      PomMailer.responsibility_override(
        message: params[:message],
        prisoner_number: @responsibility.nomis_offender_id,
        prisoner_name: OffenderService.get_offender(@responsibility.nomis_offender_id).full_name,
        prison_name: PrisonService.name_for(@prison),
        emails: emails
    ).deliver_later
    end

    redirect_to new_prison_allocation_path(@prison, @responsibility.nomis_offender_id)
  end
# rubocop:enable Metrics/LineLength

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
