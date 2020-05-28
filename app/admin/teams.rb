ActiveAdmin.register Team do
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :code, :name, :shadow_code, :local_divisional_unit_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:code, :name, :shadow_code, :local_divisional_unit_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  index do
    selectable_column
    id_column
    column :name
    column :code
    column 'Shadow code', :shadow_code
    column 'LDU', :local_divisional_unit
    column 'Offenders', sortable: :case_information_count do |team|
      team.case_information.size
    end
    column 'Created at', :created_at
    column 'Updated at', :updated_at
    actions
  end
end
