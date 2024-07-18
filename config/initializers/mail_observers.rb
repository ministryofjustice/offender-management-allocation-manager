Rails.application.reloader.to_prepare do
  ApplicationMailer.register_observer('AuditEventsMailObserver')
end
