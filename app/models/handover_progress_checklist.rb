class HandoverProgressChecklist < ApplicationRecord
  belongs_to :offender, foreign_key: :nomis_offender_id

  def progress_data
    {
      'complete' => completed_task_fields,
      'total' => 3,
    }
  end

private

  def task_fields
    [
      'reviewed_oasys',
      'contacted_com',
      'attended_handover_meeting',
    ]
  end

  def completed_task_fields
    attributes.slice(*task_fields).count { |_, v| v == true }
  end
end
