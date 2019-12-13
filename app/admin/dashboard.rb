ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  content title: proc { I18n.t('active_admin.dashboard') } do
    panel 'Offenders w/o LDU EMail Addresses' do
      ul do
        allocs = Allocation.without_ldu_emails
        case_infos_hash = CaseInformationService.get_case_information(allocs.map(&:nomis_offender_id))
        allocs.each do |allocation|
          ldu_code = case_infos_hash.fetch(alloc.nomis_offender_id).team.local_divisional_unit.code
          li " #{allocation.prison} - #{allocation.nomis_offender_id} #{ldu_code}"
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
