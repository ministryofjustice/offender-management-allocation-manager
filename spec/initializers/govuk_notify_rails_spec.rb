require 'rails_helper'

RSpec.describe 'Govuk Notify mail hooks' do
  it 'registers the expected interceptor and observers once at boot' do
    interceptors = Mail.delivery_interceptors
    observers = Mail.class_variable_get(:@@delivery_notification_observers)

    aggregate_failures do
      expect(interceptors.count { it == NotifyMailInterceptor }).to eq(1)
      expect(observers.count { it == AuditEventsMailObserver }).to eq(1)
      expect(observers.count { it == EmailHistoryMailObserver }).to eq(1)
    end
  end
end
