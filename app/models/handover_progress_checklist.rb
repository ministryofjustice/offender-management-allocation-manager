class HandoverProgressChecklist < ApplicationRecord
  belongs_to :offender, foreign_key: :nomis_offender_id

  delegate :case_allocation, to: :offender, allow_nil: true

  def progress_data
    {
      'complete' => completed_task_fields,
      'total' => task_fields.count,
    }
  end

private

  def task_fields
    fields = %w[contacted_com attended_handover_meeting]
    fields.push('reviewed_oasys') if case_allocation == 'NPS'
    fields
  end

  def completed_task_fields
    attributes.slice(*task_fields).count { |_, v| v == true }
  end
end
