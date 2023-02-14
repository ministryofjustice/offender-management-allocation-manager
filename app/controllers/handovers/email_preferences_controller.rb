class Handovers::EmailPreferencesController < PrisonsApplicationController
  def edit
    flash.keep(:current_handovers_url)
    @email_preferences = Handover::EmailPreferencesForm.load(staff_member: @current_user)
  end

  def update
    email_preferences = Handover::EmailPreferencesForm.load(staff_member: @current_user)
    email_preferences.update!(email_preferences_params)

    redirect_to helpers.last_handovers_url
  end

private

  def email_preferences_params
    params.require(:email_preferences).permit(:upcoming_handover_window, :handover_date, :com_allocation_overdue)
  end
end
