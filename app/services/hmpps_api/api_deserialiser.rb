# frozen_string_literal: true

module HmppsApi
  class ApiDeserialiser
    def deserialise_many(memory_model_class, payload_list)
      if memory_model_class.respond_to?(:from_json)
        payload_list.map { |payload|
          memory_model_class.from_json(payload)
        }
      end
    end
  end
end
