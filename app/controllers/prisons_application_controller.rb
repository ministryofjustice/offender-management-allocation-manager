# frozen_string_literal: true

# This class is inherited by all controllers under the /prisons route
# so that they have @prison and active_prison available
class PrisonsApplicationController < ApplicationController
  before_action :authenticate_user, :check_prison_access

protected

  def active_prison
    params[:prison_id]
  end

private

  def check_prison_access
    unless PrisonService.exists?(active_prison)
      redirect_to('/401')
      return
    end
    redirect_to '/401' unless caseloads.include?(active_prison)

    @prison = active_prison
  end
end
