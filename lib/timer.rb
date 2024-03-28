class Timer
  def initialize(start_time: Time.zone.now)
    @start_time = start_time
  end

  def elapsed_seconds
    Time.zone.now - @start_time
  end
end
