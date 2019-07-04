class PrisonsApplicationController < ApplicationController

  before_action :authenticate_user, :check_prison_access

protected

  def active_prison
    params[:prison_id]
  end

private

  def check_prison_access
    redirect_to '/401' unless caseloads.include?(active_prison)
    @prison = params[:prison_id]
  end
end