class HandoverProgressChecklist < ApplicationRecord
  TASK_FIELDS_FOR_CASE_ALLOCATION = {
    'NPS' => %w[reviewed_oasys contacted_com attended_handover_meeting],
    'CRC' => %w[contacted_com sent_handover_report],
  }.freeze

  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }

  belongs_to :offender, foreign_key: :nomis_offender_id

  delegate :case_allocation, to: :offender, allow_nil: true

  def self.with_incomplete_tasks
    relation
      .joins(offender: :case_information)
      .where(<<-QUERY) # generating this dynamically makes it very difficult to read so "do repeat yourself" this once
        case_information.case_allocation = 'NPS'
          AND false in ("reviewed_oasys", "contacted_com", "attended_handover_meeting")
        OR case_information.case_allocation = 'CRC'
          AND false in ("contacted_com", "sent_handover_report")
      QUERY
  end

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
    TASK_FIELDS_FOR_CASE_ALLOCATION.fetch(case_allocation)
  end

  def completed_task_fields
    attributes.slice(*task_fields).count { |_, v| v == true }
  end
end
