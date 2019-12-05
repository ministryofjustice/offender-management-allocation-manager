ActiveAdmin.register LocalDivisionalUnit, as: 'LDU' do
  permit_params :code, :name, :email_address
end
