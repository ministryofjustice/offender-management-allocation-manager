class HandoverProgressChecklist < ApplicationRecord
  include Auditable

  SIMPLIFIED_ENHANCED_HANDOVER_TASK_FIELDS = %w[reviewed_oasys contacted_com].freeze
  ENHANCED_HANDOVER_TASK_FIELDS = %w[reviewed_oasys contacted_com attended_handover_meeting].freeze
  STANDARD_HANDOVER_TASK_FIELDS = %w[contacted_com sent_handover_report].freeze

  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }

  after_commit :save_audit_event

  belongs_to :offender, foreign_key: :nomis_offender_id

  delegate :handover_type, :handover_date, to: :offender

  def self.permitted_task_fields(handover_type:, handover_date:)
    cutoff = Rails.configuration.x.simplified_handover_cutoff_date

    if handover_type != 'enhanced'
      STANDARD_HANDOVER_TASK_FIELDS
    elsif FeatureFlags.simplified_enhanced_handover.enabled? && handover_date.present? && handover_date > cutoff
      SIMPLIFIED_ENHANCED_HANDOVER_TASK_FIELDS
    else
      ENHANCED_HANDOVER_TASK_FIELDS
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
    self.class.permitted_task_fields(handover_type:, handover_date:).map(&:to_s)
  end

  def task_attributes
    attributes.slice(*task_fields)
  end

  def completed_task_attributes
    task_attributes.count { |_, v| v == true }
  end

  def audit_event_tags
    %w[record handover_progress_checklist changed].freeze
  end
end
