# frozen_string_literal: true

class ApiDeserialiser
  def deserialise_many(memory_model_class, payload_list)
    safe_list = payload_list.to_snake_keys
    safe_list.map { |item|
      deserialise_hash(memory_model_class, item)
    }
  end

  def deserialise(memory_model_class, payload)
    deserialise_hash(memory_model_class, payload.to_snake_keys)
  end

private

  def deserialise_hash(memory_model_class, payload)
    memory_model = memory_model_class.new

    payload.each do |key, value|
      setter = "#{key}="
      if memory_model.respond_to?(setter)
        memory_model.public_send(setter, value)
      else
        raise_warning_for(memory_model_class, key)
      end
    end

    memory_model
  end

  def raise_warning_for(klass, key)
    Rails.logger.info("#{klass} is missing field #{key}")
  end
end
