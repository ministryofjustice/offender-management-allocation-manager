# This module provides a helper for deserialising dates from a payload
# provided from one of the API calls.  We need this to be available at
# class and instance level, hence the two definitions.
module Deserialisable
  include ActiveSupport::Concern

  def self.included(base)
    def base.deserialise_date(payload, field)
      return nil unless payload.key? field

      Date.parse(payload[field])
    end
  end

  def deserialise_date(payload, field)
    self.class.deserialise_date(payload, field)
  end
end
