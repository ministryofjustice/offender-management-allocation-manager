require 'irb/helper_method'

class WithAuditNotesHelper < IRB::HelperMethod::Base
  description 'Ensure that paper_trail fields are correctly filled when performing manual changes on the console'

  def execute(user_first_name:, user_last_name:, note:)
    whodunnit = "#{user_first_name} #{user_last_name}"
    controller_info = { user_first_name:, user_last_name:, system_admin_note: note }

    PaperTrail.request(whodunnit:, controller_info:) do
      yield if block_given?
    end
  end
end

IRB::HelperMethod.register(:with_audit_notes, WithAuditNotesHelper)
