# frozen_string_literal: true

class PagesController < ApplicationController
  layout 'errors_and_contact'

  def help; end

  def guidance; end

  def contact
    @contact = nil
  end

  def create_contact
    @user = Nomis::Elite2::UserApi.user_details(current_user)
    @contact = ContactSubmission.new(
        name: contact_params[:name],
        role: contact_params[:role],
        email_address: contact_params[:email_address],
        prison: contact_params[:prison],
        body: contact_params[:more_detail],
        user_agent: request.headers['HTTP_USER_AGENT'],
        referrer: request.referrer
    )
    if @contact.save
      ZendeskTicketsJob.perform_later(@contact)
      redirect_to contact_path
                  flash[:notice] = "Your contact form has been submitted"
    else
      render :contact
    end
  end

private

  def contact_params
    params.permit(:more_detail, :email_address, :name, :prison, :role)
  end
end
