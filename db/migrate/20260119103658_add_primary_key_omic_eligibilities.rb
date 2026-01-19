class AddPrimaryKeyOmicEligibilities < ActiveRecord::Migration[8.1]
  def up
    execute "ALTER TABLE omic_eligibilities ADD PRIMARY KEY (nomis_offender_id)"

    add_column :omic_eligibilities, :prison, :string
    add_index  :omic_eligibilities, :prison
  end

  def down
    remove_index  :omic_eligibilities, :prison
    remove_column :omic_eligibilities, :prison

    execute "ALTER TABLE omic_eligibilities DROP CONSTRAINT omic_eligibilities_pkey"
  end
end
