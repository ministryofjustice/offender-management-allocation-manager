class CreateParoleRecords < ActiveRecord::Migration[6.0]
  def change
    create_table :parole_records, id: false do |t|
      t.string :nomis_offender_id, primary_key: true
      t.date :parole_review_date, null: false

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        CaseInformation.includes(:offender).where.not(parole_review_date: nil).find_each do |ci|
          offender = ci.offender.present? ? ci.offender : ci.create_offender!(nomis_offender_id: ci.nomis_offender_id)
          offender.create_parole_record!(parole_review_date: ci.parole_review_date)
        end
        remove_column :case_information, :parole_review_date
      end
      dir.down do
        add_column :case_information, :parole_review_date, :date
        ParoleRecord.find_each do |pr|
          pr.offender.case_information.update!(parole_review_date: pr.parole.review_date)
        end
      end
    end
  end
end
