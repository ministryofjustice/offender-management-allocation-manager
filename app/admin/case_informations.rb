if ENV['HEROKU_APP_NAME'].present?
  ActiveAdmin.register CaseInformation do
    permit_params :tier, :case_allocation, :crn, :mappa_level, :manual_entry, :target_hearing_date, :probation_service, :com_name, :team_name, :local_delivery_unit_id, :nomis_offender_id, :ldu_code

    form do |form|
      inputs do
        # This list is the Offenders w/o case info, plus the current one for 'edit' mode
        offenders = (Offender.left_joins(:case_information).where('case_information.nomis_offender_id is null') + [form.object.offender]).compact
        input :offender,
              collection: offenders.map { |offender| [offender.nomis_offender_id, offender.nomis_offender_id] }
        input :tier, collection: ['A', 'B', 'C', 'D']
        input :case_allocation, collection: ['NPS', 'CRC']
        input :crn
        input :mappa_level, as: :select, collection: [['Unknown', nil], ['None', 0], ['Level 1', 1], ['Level 2', 2], ['Level 3', 3]]
        input :manual_entry
        input :target_hearing_date, as: :datepicker
        input :probation_service, collection: ['Wales', 'England']
        input :com_name
        input :team_name
        input :local_delivery_unit
      end
      actions
    end
  end
end
