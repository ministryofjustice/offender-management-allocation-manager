require 'console_display_helpers'

Rails.application.configure do
  console do
    Rails::ConsoleMethods.include(ConsoleDisplayHelpers)
    Rails::ConsoleMethods.include(ConsoleAuditHelpers)
    Rails::ConsoleMethods.include(ConsoleDebugOffenderHelpers)
  end
end
