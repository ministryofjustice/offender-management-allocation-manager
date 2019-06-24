class AddDeliusDataTable < ActiveRecord::Migration[5.2]
  def up
    create_table :delius_data do |t|
      t.string :crn
      t.string :pnc_no
      t.string :noms_no, index: {unique: true}
      t.string :fullname
      t.string :tier
      t.string :roh_cds
      t.string :offender_manager
      t.string :org_private_ind
      t.string :org
      t.string :provider
      t.string :provider_code
      t.string :ldu
      t.string :ldu_code
      t.string :team
      t.string :team_code
      t.string :mappa
      t.string :mappa_levels
      t.timestamps
    end
  end

  def down
    drop_table :delius_data
  end

end
