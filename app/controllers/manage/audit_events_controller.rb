class Manage::AuditEventsController < ApplicationController
  # Kaminari default is set to 50 results, but here we don't need that many
  RESULTS_PER_PAGE = 25

  before_action :authenticate_user, :ensure_admin_user

  def index
    @tags = []
    @audit_events = AuditEvent.order(created_at: :desc).page(params[:page]).per(RESULTS_PER_PAGE).without_count
  end

  def search
    @nomis_offender_id = params[:nomis_offender_id]&.strip
    @username = params[:whodunnit]&.strip
    @tags = params.fetch(:tags, '').strip.split(/[^\w.=]+/)

    query = AuditEvent.order(created_at: :desc)

    if @nomis_offender_id.present?
      query = query.where(nomis_offender_id: @nomis_offender_id)
    end

    if @tags.present?
      query = query.tags(*@tags)
    end

    if @username.present?
      query = if @username.casecmp('system').zero?
                query.where(system_event: true)
              else
                query.where(username: @username)
              end
    end

    @audit_events = query.page(params[:page]).per(RESULTS_PER_PAGE).without_count
    render :index
  end
end
