module DomainEvents::EventFactory
  class << self
    def build_handover_event(noms_number:, host:)
      DomainEvents::Event.new(
        event_type: 'domain-events.handover.changed',
        version: 1,
        description: 'Handover date and/or responsibility was updated',
        detail_url: "#{host}/handovers/#{noms_number}",
        noms_number: noms_number,
      )
    end
  end
end
