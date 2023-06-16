class Manage::AuditEventsController < PrisonsApplicationController
  def index
    @nomis_offender_id = params[:nomis_offender_id]
    query = AuditEvent.order(published_at: :desc)

    if @nomis_offender_id.present?
      query = query.where(nomis_offender_id: @nomis_offender_id)
    end

    @audit_events = query.page params[:page]
  end
end
