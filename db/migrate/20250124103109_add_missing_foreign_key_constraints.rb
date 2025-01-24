class AddMissingForeignKeyConstraints < ActiveRecord::Migration[7.1]
  def change
    # Offenders - NOMIS ID
    # add_foreign_key :allocation_history, :offenders, column: :nomis_offender_id, primary_key: :nomis_offender_id
    # add_foreign_key :audit_events, :offenders, column: :nomis_offender_id, primary_key: :nomis_offender_id
    add_foreign_key :calculated_early_allocation_statuses, :offenders, column: :nomis_offender_id, primary_key: :nomis_offender_id
    # add_foreign_key :calculated_handover_dates, :offenders, column: :nomis_offender_id, primary_key: :nomis_offender_id
    # add_foreign_key :case_information, :offenders, column: :nomis_offender_id, primary_key: :nomis_offender_id
    add_foreign_key :delius_import_errors, :offenders, column: :nomis_offender_id, primary_key: :nomis_offender_id
    add_foreign_key :early_allocations, :offenders, column: :nomis_offender_id, primary_key: :nomis_offender_id
    add_foreign_key :email_histories, :offenders, column: :nomis_offender_id, primary_key: :nomis_offender_id
    # add_foreign_key :parole_reviews, :offenders, column: :nomis_offender_id, primary_key: :nomis_offender_id
    # add_foreign_key :parole_review_imports, :offenders, column: :nomis_id, primary_key: :nomis_offender_id
    add_foreign_key :responsibilities, :offenders, column: :nomis_offender_id, primary_key: :nomis_offender_id
    # add_foreign_key :versions, :offenders, column: :nomis_offender_id, primary_key: :nomis_offender_id
    add_foreign_key :victim_liaison_officers, :offenders, column: :nomis_offender_id, primary_key: :nomis_offender_id

    # Local delivery units
    add_foreign_key :case_information, :local_delivery_units, column: :local_delivery_unit_id, primary_key: :id
    # add_foreign_key :case_information, :local_delivery_units, column: :ldu_code, primary_key: :code

    # Prisons
    add_foreign_key :pom_details, :prisons, column: :prison_code, primary_key: :code
  end
end
