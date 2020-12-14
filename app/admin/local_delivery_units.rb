# frozen_string_literal: true

ActiveAdmin.register LocalDeliveryUnit do
  menu label: 'Local Delivery Units'

  permit_params :code, :name, :email_address, :country, :enabled

  form do |_form|
    inputs do
      input :code
      input :name
      input :email_address
      input :country, as: :select, collection: LocalDeliveryUnit::VALID_COUNTRIES
      input :enabled
    end
    actions
  end
end
