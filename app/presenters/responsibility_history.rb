# frozen_string_literal: true

class ResponsibilityHistory < BaseHistoryPresenter
  delegate :created_at, :event, to: :@version

  def initialize(version)
    super()
    @version = version
  end

  def to_partial_path
    "case_history/responsibility/#{event}"
  end

  def created_by_name
    paper_trail_created_by_name(@version)
  end

  def reason_detail
    system_reason = changed_value_for('reason')
    reason = (Responsibility.reasons.key(system_reason) || system_reason).to_s
    reason_label = Responsibility.human_reason(reason)

    return if reason_label.blank?

    if reason == 'other_reason'
      [reason_label, changed_value_for('reason_text').presence].compact.join(' – ')
    else
      reason_label
    end
  end

  def changed_value_for(attribute)
    Array((@version.changeset || {})[attribute]).second
  end
end
