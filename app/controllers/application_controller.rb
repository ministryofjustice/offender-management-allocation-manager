# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :current_user
  helper_method :caseloads

  before_action :set_paper_trail_whodunnit

  def authenticate_user
    if sso_identity.absent? || sso_identity.session_expired?
      session[:redirect_path] = request.original_fullpath
      redirect_to '/auth/hmpps_sso'
    else
      redirect_to '/401' unless sso_identity.allowed?
    end
  end

  def current_user
    sso_identity.current_user
  end

  def current_user_is_spo?
    sso_identity.current_user_is_spo?
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

  def default_prison_code
    sso_identity.default_prison_code
  end

  def caseloads
    sso_identity.caseloads
  end

  # called by active admin
  def access_denied(_active_admin_context)
    redirect_to '/401'
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

private

  def sso_identity
    @sso_identity ||= SsoIdentity.new session
  end
end
