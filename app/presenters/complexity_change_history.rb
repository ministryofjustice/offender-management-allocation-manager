class ComplexityChangeHistory
  delegate :created_at, :prison, :level, :created_by_name, to: :@current
  attr_reader :reasons

  def initialize(previous, current)
    @previous = previous
    @current = ComplexityNewHistory.new(current)
    @reasons = current.fetch(:notes)
  end

  def previous_level
    @previous.fetch(:level).titleize
  end

  def to_partial_path
    'case_history/complexity/change'
  end
end
