module Health
  KeyValueCheck = Struct.new(:key, :value, keyword_init: true) do
    include StatusCheck

    def perform(get_response)
      response = get_response.call

      if key.present?
        response[key] == value
      else
        response == value
      end
    end
  end
end
