class AddOffenderIdToVlo < ActiveRecord::Migration[6.0]
  def change
    change_table :victim_liaison_officers do |vlo_table|
      vlo_table.string :nomis_offender_id, limit: 7, index: true
    end

    reversible do |dir|
      dir.up {
        VictimLiaisonOfficer.includes(case_information: :offender).find_each do |vlo|
          ci = vlo.case_information
          ci.create_offender!(nomis_offender_id: ci.nomis_offender_id) unless ci.offender.present?
          vlo.update!(nomis_offender_id: ci.nomis_offender_id)
        end
      }
    end
    change_column_null :victim_liaison_officers, :nomis_offender_id, false
  end
end
