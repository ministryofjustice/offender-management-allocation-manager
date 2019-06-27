# frozen_string_literal: true

class PagesController < ApplicationController
  include ActiveModel::Validations

  validates :more_detail, presence: true

  def help; end

  def contact
    @contact = nil
  end

  def create_contact
    @contact = Contact.new(contact_params[:more_detail])
    @contact.valid?

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
