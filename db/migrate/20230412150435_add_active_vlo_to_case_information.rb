class AddActiveVloToCaseInformation < ActiveRecord::Migration[6.1]
  def change
    add_column :case_information, :active_vlo, :boolean, default: false
  end
end
