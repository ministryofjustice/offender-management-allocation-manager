# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :set_paper_trail_whodunnit

  delegate :default_prison_code, :caseloads, :current_user_is_spo?, to: :sso_identity
  delegate :current_user, :current_staff_id, to: :sso_identity, allow_nil: true

  helper_method :current_user,
                :current_staff_id,
                :current_user_is_spo?,
                :dps_header_footer,
                :default_prison_code

  def authenticate_user
    if sso_identity.absent? || sso_identity.session_expired?
      session[:redirect_path] = request.original_fullpath
      redirect_to '/auth/hmpps_sso'
    else
      redirect_to '/401' unless sso_identity.allowed?
    end
  end

  def ensure_spo_user
    unless current_user_is_spo?
      redirect_to '/401'
    end
  end

  def ensure_admin_user
    unless sso_identity.current_user_is_admin?
      redirect_to '/401'
    end
  end

  # Store an object's attributes to the session
  # Use this method to safely serialize ActiveRecord objects (or those with an #attributes method).
  # ActiveRecord objects can later be re-hydrated by calling MyModel.new() with attributes loaded from the session.
  # This works around inconsistencies between writing objects to different Rails session stores (e.g. cookie vs cache).
  # Underlying principle: Never store complex objects in the session – they won't always re-hydrate as you expect.
  # Instead, only store JSON-safe primitives (i.e. Hash, Array, String, Number, Boolean, Nil) and re-hydrate them yourself.
  def save_to_session(key, record)
    session[key] = record.attributes
  end

  def dps_header_footer
    return { 'status' => 'fallback' } if params[:fallback_header_footer].present?
    return @dps_header_footer if @dps_header_footer

    begin
      @dps_header_footer ||= {
        'header' => HmppsApi::DpsFrontendComponentsApi.header(sso_identity.token),
        'footer' => HmppsApi::DpsFrontendComponentsApi.footer(sso_identity.token),
        'status' => 'ok',
      }
    rescue Faraday::ServerError, Faraday::ClientError, NoMethodError => e
      logger.error "event=dps_header_footer_retrieval_error|#{e.inspect},#{e.backtrace.join(',')}"
      @dps_header_footer ||= { 'status' => 'fallback' }
    end

    @dps_header_footer
  end

private

  def sso_identity
    @sso_identity ||= SsoIdentity.new session
  end
end
