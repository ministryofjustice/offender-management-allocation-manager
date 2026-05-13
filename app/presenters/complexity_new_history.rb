class ComplexityNewHistory < BaseHistoryPresenter
  def initialize(history)
    super()
    @history = history
  end

  def created_at
    @history.fetch(:createdTimeStamp).getlocal
  end

  def level
    @history.fetch(:level).titleize
  end

  def prison
    nil
  end

  def to_partial_path
    'case_history/complexity/new'
  end

  def created_by_name
    nomis_created_by_name(@history[:sourceUser])
  end
end
