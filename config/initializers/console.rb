Rails.application.configure do
  console do
    require_relative '../../app/lib/with_audit_notes_helper'
  end
end
