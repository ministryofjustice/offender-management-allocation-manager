class Handovers::EmailPreferencesController < PrisonsApplicationController
  FIELDS = Handover::EmailPreferencesForm::FIELDS

  def edit
    flash.keep(:current_handovers_url)
    @email_preferences = Handover::EmailPreferencesForm.load_opt_outs(staff_member: @current_user)
  end

  def update
    email_preferences = Handover::EmailPreferencesForm.load_opt_outs(staff_member: @current_user)
    email_preferences.update!(email_preferences_params)

    redirect_to helpers.last_handovers_url
  end

private

  def email_preferences_params
    params.require(:email_preferences).permit(*FIELDS)
  end
end
