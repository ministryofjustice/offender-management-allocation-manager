# frozen_string_literal: true

ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  content title: proc { I18n.t('active_admin.dashboard') } do
    panel 'Offenders w/o LDU Email Addresses' do
      allocations = AllocationHistory.without_ldu_emails
      case_infos_hash = CaseInformation.where(nomis_offender_id: allocations.select(:nomis_offender_id)).index_by(&:nomis_offender_id)
      para "Total: #{allocations.count}"
      table_for(allocations, style: 'max-width: 350px') do
        column 'Prison', :prison
        column 'Offender', :nomis_offender_id
        column('LDU code') { |allocation| case_infos_hash[allocation.nomis_offender_id].ldu_code }
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
