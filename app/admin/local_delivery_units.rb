# frozen_string_literal: true

ActiveAdmin.register LocalDeliveryUnit do
  menu label: 'Local Delivery Units'

  actions :index
  config.sort_order = 'name_asc'

  index do
    column :id
    column :code
    column :name
    column :email_address
    column :country
    column :created_at
    column :updated_at
    column :mailbox_register_id
  end

  # Filter fields
  preserve_default_filters!
  remove_filter :case_information, :enabled
end
