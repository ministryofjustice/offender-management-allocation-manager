class HandoverProgressChecklist < ApplicationRecord
  ENHANCED_HANDOVER_TASK_FIELDS = %w[reviewed_oasys contacted_com attended_handover_meeting].freeze
  NORMAL_HANDOVER_TASK_FIELD = %w[contacted_com sent_handover_report].freeze

  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }

  belongs_to :offender, foreign_key: :nomis_offender_id

  delegate :enhanced_handover?, to: :offender

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
    enhanced_handover? ? ENHANCED_HANDOVER_TASK_FIELDS : NORMAL_HANDOVER_TASK_FIELD
  end

  def task_attributes
    attributes.slice(*task_fields)
  end

  def completed_task_attributes
    task_attributes.count { |_, v| v == true }
  end
end
