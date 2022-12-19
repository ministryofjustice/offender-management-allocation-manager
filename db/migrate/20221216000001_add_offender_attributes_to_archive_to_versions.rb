class AddOffenderAttributesToArchiveToVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :versions, :offender_attributes_to_archive, :jsonb
  end
end
