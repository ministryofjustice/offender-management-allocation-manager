# frozen_string_literal: true

# This class is inherited by all controllers under the /prisons route
# so that they have @prison and active_prison_id available
class PrisonsApplicationController < ApplicationController
  include Sorting

  before_action :authenticate_user, :check_prison_access, :load_staff_member, :service_notifications, :load_roles,
                :check_active_caseload

protected

  def active_prison_id
    params.fetch(:prison_id, default_prison_code)
  end

  def ensure_pom
    unless current_user_is_pom?
      redirect_to '/401'
    end
  end

  def current_user_is_pom?
    sso_identity.current_user_is_pom? && @current_user.has_pom_role?
  end
  helper_method :current_user_is_pom?

  # This is the data for the quite lengthy allocation summary message that appears
  # on the confirm page and as a success message after allocation.
  #
  # No good storing the redered HTML in flash as it will blow the max cookie
  # size. Instead we just store the locals in the session, which gets rendered
  # via a partial if @latest_allocation_details is present.
  def retrieve_latest_allocation_details
    @latest_allocation_details = session[:latest_allocation_details]&.with_indifferent_access
    session.delete(:latest_allocation_details)
  end

private

  def load_roles
    @is_pom = current_user_is_pom?
    @is_spo = current_user_is_spo?
  end

  def check_prison_access
    unless Prison.exists?(code: active_prison_id)
      redirect_to('/401')
      return
    end

    return redirect_to('/401') if caseloads.nil? || !caseloads.include?(active_prison_id)

    @prison = Prison.find(active_prison_id)
    @caseloads = caseloads
  end

  def load_staff_member
    user = HmppsApi::PrisonApi::UserApi.user_details(current_user)
    @current_user = StaffMember.new(@prison, user.staff_id)
    @staff_id = user.staff_id
  end

  def service_notifications
    roles = [current_user_is_spo? ? 'SPO' : nil, sso_identity.current_user_is_pom? ? 'POM' : nil].compact
    @service_notifications = ServiceNotificationsService.notifications(roles)
  end

  def page
    params.fetch('page', 1).to_i
  end

  def set_referrer
    @referrer = referrer
  end

  def referrer
    session[:referrer] || request.referer || root_path
  end

  def store_referrer_in_session
    session[:referrer] = request.referer
  end

  def sort_and_paginate(cases)
    sorted_cases = sort_collection cases, default_sort: :handover_date, default_direction: :asc
    Kaminari.paginate_array(sorted_cases).page(page)
  end

  def check_active_caseload
    prison_id = params[:prison_id]
    return if prison_id.blank?

    active_caseload_id = HmppsApi::ActiveCaseloadApi.current_user_active_caseload(sso_identity.token)
    if active_caseload_id != params[:prison_id]
      flash[:notice] = t('views.navigation.enforce_active_caseload', name: Prison.find_by_code(active_caseload_id).name)
      session.delete(:sso_data)
      redirect_to prison_dashboard_index_path(prison_id: active_caseload_id)
    end
  end
end
