# frozen_string_literal: true

# This class is inherited by all controllers under the /prisons route
# so that they have @prison and active_prison_id available
class PrisonsApplicationController < ApplicationController
  before_action :authenticate_user, :check_prison_access

protected

  def active_prison_id
    params[:prison_id]
  end

private

  def check_prison_access
    unless PrisonService.exists?(active_prison_id)
      redirect_to('/401')
      return
    end

    return redirect_to('/401') if caseloads.nil? || !caseloads.include?(active_prison_id)

    @prison = Prison.new(active_prison_id)
  end
end
