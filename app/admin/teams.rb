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
end
