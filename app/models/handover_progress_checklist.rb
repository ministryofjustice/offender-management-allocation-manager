class HandoverProgressChecklist < ApplicationRecord
  SIMPLIFIED_ENHANCED_HANDOVER_TASK_FIELDS = %w[reviewed_oasys contacted_com].freeze
  ENHANCED_HANDOVER_TASK_FIELDS = %w[reviewed_oasys contacted_com attended_handover_meeting].freeze
  STANDARD_HANDOVER_TASK_FIELDS = %w[contacted_com sent_handover_report].freeze

  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }

  belongs_to :offender, foreign_key: :nomis_offender_id

  delegate :handover_type, to: :offender

  def self.permitted_task_fields(handover_type:, simplified_enhanced_handover: FeatureFlags.simplified_enhanced_handover.enabled?)
    if handover_type == 'enhanced'
      simplified_enhanced_handover ? SIMPLIFIED_ENHANCED_HANDOVER_TASK_FIELDS : ENHANCED_HANDOVER_TASK_FIELDS
    else
      STANDARD_HANDOVER_TASK_FIELDS
    end.map(&:to_sym)
  end

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
    self.class.permitted_task_fields(handover_type:).map(&:to_s)
  end

  def task_attributes
    attributes.slice(*task_fields)
  end

  def completed_task_attributes
    task_attributes.count { |_, v| v == true }
  end
end
