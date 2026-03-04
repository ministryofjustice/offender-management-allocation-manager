# frozen_string_literal: true

module HmppsApi
  module Error
    class Unauthorized < Faraday::UnauthorizedError; end
  end
end
