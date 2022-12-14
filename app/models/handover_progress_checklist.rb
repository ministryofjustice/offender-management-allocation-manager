class HandoverProgressChecklist < ApplicationRecord
  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }

  belongs_to :offender, foreign_key: :nomis_offender_id

  delegate :case_allocation, to: :offender, allow_nil: true

  def progress_data
    {
      'complete' => completed_task_fields,
      'total' => task_fields.count,
    }
  end

  def task_completion_data
    attributes.slice(*task_fields)
  end

private

  def task_fields
    if case_allocation == 'NPS'
      %w[reviewed_oasys contacted_com attended_handover_meeting]
    else
      %w[contacted_com sent_handover_report]
    end
  end

  def completed_task_fields
    attributes.slice(*task_fields).count { |_, v| v == true }
  end
end
