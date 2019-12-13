ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  content title: proc { I18n.t('active_admin.dashboard') } do
    # div class: 'blank_slate_container', id: 'dashboard_default_message' do
    #   span class: 'blank_slate' do
    #     span I18n.t('active_admin.dashboard_welcome.welcome')
    #     small I18n.t('active_admin.dashboard_welcome.call_to_action')
    #   end
    # end

    panel 'Problematic Offenders' do
      ul do
        a = Allocation.all.map(&:nomis_offender_id)
        off = CaseInformationService.get_case_information(a).values.select { |ci|
          ci.team.try(:local_divisional_unit).try(:email_address).nil?
        }.map(&:nomis_offender_id)
        Allocation.where(nomis_offender_id: off).each do |allocation|
          li " #{allocation.prison} - #{allocation.nomis_offender_id}"
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
