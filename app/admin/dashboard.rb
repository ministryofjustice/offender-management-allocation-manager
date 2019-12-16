ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  content title: proc { I18n.t('active_admin.dashboard') } do
    panel 'Offenders w/o LDU EMail Addresses' do
      ul do
        allocations = Allocation.without_ldu_emails
        case_infos_hash = CaseInformationService.get_case_information(allocations.map(&:nomis_offender_id))
        allocations.each do |allocation|
          ldu_code = case_infos_hash.fetch(allocation.nomis_offender_id).team.try(:local_divisional_unit).try(:code)
          li "Prison #{allocation.prison} Offender #{allocation.nomis_offender_id} LDU Code #{ldu_code}"
        end
      end
    end

    # Here is an example of a simple dashboard with columns and panels.
    #
    # columns do
    #   column do
    #     panel "Recent Posts" do
    #       ul do
    #         Post.recent(5).map do |post|
    #           li link_to(post.title, admin_post_path(post))
    #         end
    #       end
    #     end
    #   end

    #   column do
    #     panel "Info" do
    #       para "Welcome to ActiveAdmin."
    #     end
    #   end
    # end
  end
end
