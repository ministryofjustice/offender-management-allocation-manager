# frozen_string_literal: true

module HmppsApi
  class ApiDeserialiser
    def deserialise_many(memory_model_class, payload_list)
      if memory_model_class.respond_to?(:from_json)
        payload_list.map do |payload|
          memory_model_class.from_json(payload)
        end
      end
    end

    def deserialise(memory_model_class, payload)
      # Ask the class to deserialize the payload into an instance if it knows how to,
      # otherwise will rely on the `public_send` process.
      if memory_model_class.respond_to?(:from_json)
        memory_model_class.from_json(payload)
      end
    end
  end
end
