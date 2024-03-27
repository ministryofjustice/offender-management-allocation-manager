module Health
  KeyValueCheck = Struct.new(:key, :value, keyword_init: true) do
    include StatusCheck

    def perform(get_response)
      if key.present?
        get_response.call[key] == value
      else
        get_response.call == value
      end
    end
  end
end
