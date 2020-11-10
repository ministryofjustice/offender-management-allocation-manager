# frozen_string_literal: true

class ResponsibilitiesController < PrisonsApplicationController
  def new
    if ldu_email_address(nomis_offender_id_from_url).present?
      @responsibility = Responsibility.new nomis_offender_id: nomis_offender_id_from_url
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

    me = HmppsApi::PrisonApi::UserApi.user_details(current_user).email_address.try(:first)

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

    allocation = Allocation.find_by(nomis_offender_id: @responsibility.nomis_offender_id, prison: @prison.code)
    if allocation.try(:active?)
      redirect_to prison_allocation_path(@prison.code, @responsibility.nomis_offender_id)
    else
      redirect_to new_prison_allocation_path(@prison.code, @responsibility.nomis_offender_id)
    end
  end

  def confirm_removal
    @responsibility = RemoveResponsibilityForm.new nomis_offender_id: nomis_offender_id_from_url
    @ldu_email_address = ldu_email_address(nomis_offender_id_from_url)
  end

  def destroy
    @responsibility = RemoveResponsibilityForm.new(responsibility_params)
    @ldu_email_address = ldu_email_address(nomis_offender_id_from_url)

    allocation = Allocation.find_by(nomis_offender_id: nomis_offender_id_from_url)

    emails = [@current_user.email_address, @ldu_email_address]

    if @responsibility.valid?
      Responsibility.find_by!(nomis_offender_id: nomis_offender_id_from_url).destroy
      offender = OffenderService.get_offender(nomis_offender_id_from_url)

      if allocation && allocation.active?
        pom_email = HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(allocation.primary_pom_nomis_id).first
        emails << pom_email
        ResponsibilityMailer.responsibility_to_custody_with_pom(emails: emails.compact,
                                                                       pom_name: allocation.primary_pom_name,
                                                                       pom_email: pom_email,
                                                                       prisoner_name: offender.full_name,
                                                                       prisoner_number: nomis_offender_id_from_url,
                                                                       prison_name: @prison.name,
                                                                       notes: @responsibility.reason_text).deliver_later
      else
        ResponsibilityMailer.responsibility_to_custody(emails: emails.compact,
                                                       prisoner_name: offender.full_name,
                                                       prisoner_number: nomis_offender_id_from_url,
                                                       prison_name: @prison.name,
                                                       notes: @responsibility.reason_text).deliver_later
      end

      redirect_to new_prison_allocation_path(@prison.code, nomis_offender_id_from_url)
    else
      render :confirm_removal
    end
  end

private

  def nomis_offender_id_from_url
    params.fetch(:nomis_offender_id)
  end

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
