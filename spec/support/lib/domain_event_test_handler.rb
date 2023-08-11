class DomainEventTestHandler
  class << self
    def save_handled_event(event)
      @handled_events ||= []
      @handled_events.push(event)
    end

    def handled_events
      @handled_events || []
    end

    def clear_handled_events
      @handled_events = []
    end
  end

  def handle(event)
    self.class.save_handled_event(event)
  end
end
