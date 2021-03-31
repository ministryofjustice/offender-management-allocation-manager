class ComplexityNewHistory
  def initialize(history)
    @history = history
  end

  def created_at
    @history.fetch(:createdTimeStamp)
  end

  def level
    @history.fetch(:level).titleize
  end

  def prison
    nil
  end

  def to_partial_path
    'case_history/new_complexity'
  end

  def created_by_name
    username = @history[:sourceUser]
    if username
      user = HmppsApi::PrisonApi::UserApi.user_details(username)
      "#{user.last_name}, #{user.first_name}".titleize
    end
  end
end
