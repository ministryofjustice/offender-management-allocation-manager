class HandoverProgressChecklist < ApplicationRecord
  TASK_FIELDS_FOR_CASE_ALLOCATION = {
    'NPS' => %w[reviewed_oasys contacted_com attended_handover_meeting],
    'CRC' => %w[contacted_com sent_handover_report],
  }.freeze

  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }

  belongs_to :offender, foreign_key: :nomis_offender_id

  delegate :case_allocation, to: :offender, allow_nil: true

  def progress_data
    {
      'complete' => completed_task_attributes,
      'total' => task_fields.count,
    }
  end

  def task_completion_data
    attributes.slice(*task_fields)
  end

  def handover_progress_complete?
    task_attributes.all? { |_, v| v == true }
  end

private

  def task_fields
    TASK_FIELDS_FOR_CASE_ALLOCATION.fetch(case_allocation)
  end

  def task_attributes
    attributes.slice(*task_fields)
  end

  def completed_task_attributes
    task_attributes.count { |_, v| v == true }
  end
end
