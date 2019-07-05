# frozen_string_literal: true

class PagesController < ApplicationController
  layout 'errors_and_contact'

  def help; end

  def contact
    @contact = nil
  end

  def create_contact
    @contact = Contact.new(contact_params[:more_detail])

    if @contact.valid?
      redirect_to contact_path
    else
      render :contact
    end
  end

private

  def contact_params
    params.permit(:more_detail)
  end
end
