Rails.application.configure do
  console do
    def with_audit_notes(user_first_name:, user_last_name:, note:)
      whodunnit = "#{user_first_name} #{user_last_name}"
      controller_info = { user_first_name:, user_last_name:, system_admin_note: note }

      PaperTrail.request(whodunnit:, controller_info:) do
        yield if block_given?
      end
    end
  end
end
