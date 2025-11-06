class Manage::AuditEventsController < ApplicationController
  before_action :authenticate_user, :ensure_admin_user

  def index
    @nomis_offender_id = params[:nomis_offender_id]
    @tags = params.fetch(:tags, '').strip.split(/[^\w.=]+/)
    query = AuditEvent.order(published_at: :desc)

    if @nomis_offender_id.present?
      query = query.where(nomis_offender_id: @nomis_offender_id)
    end

    if @tags.present?
      query = query.tags(*@tags)
    end

    @audit_events = query.page params[:page]
  end
end
