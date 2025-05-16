require 'console_display_helpers'

Rails.application.configure do
  console do
    Rails::ConsoleMethods.include(ConsoleAuditHelpers)
  end
end
