class FeedbackController < PrisonsApplicationController
  before_action :authenticate_user

  def new
    @user = Nomis::Elite2::UserApi.user_details(current_user)
    @feedback = FeedbackSubmission.new(
        email_address: @user.email_address.first,
        prison_id: @user.active_nomis_caseload)
  end

  def create
    @feedback = FeedbackSubmission.new(feedback_params)
    byebug
    if @feedback.save
      ZendeskTicketsJob.perform_later(@feedback)
      redirect_to prison_dashboard_index_path(default_prison_code),
                  flash[:notice] = "Feedback has been submitted"
    else
      render :new
    end
  end

  private

  def feedback_params
    params.
        require(:feedback_submission).
        permit(:referrer, :body, :email_address, :user_agent, :prison_id)
  end
end