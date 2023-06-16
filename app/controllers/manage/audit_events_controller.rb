class Manage::AuditEventsController < PrisonsApplicationController
  def index
    @audit_events = AuditEvent.order(published_at: :desc).all
  end
end
