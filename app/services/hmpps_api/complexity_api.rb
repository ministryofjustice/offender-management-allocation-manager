# frozen_string_literal: true

module HmppsApi
  class ComplexityApi
    class << self
      def get_complexity(offender_no)
        route = "/complexity-of-need/offender-no/#{offender_no}"
        begin
          result = client.get route, cache: false
          result.fetch('level')
        rescue Faraday::ResourceNotFound
          nil
        end
      end

      def save(offender_no, level:, username:, reason:)
        route = "/complexity-of-need/offender-no/#{offender_no}"
        client.post route, { level: level, sourceUser: username, notes: reason }, cache: false
      end

      def get_complexities(offender_nos)
        route = '/complexity-of-need/multiple/offender-no'
        result = client.post route, [offender_nos], cache: false
        result.map { |complexity| [complexity.fetch('offenderNo'), complexity.fetch('level')] }.to_h
      end

      def get_history(offender_no)
        route = "/complexity-of-need/offender-no/#{offender_no}/history"
        results = client.get route, cache: false
        # TODO: - this list is currently served reversed by the complexity API
        # it could be changed to forward-serve at which point this sort could be removed
        results.sort_by { |item| item.fetch('createdTimeStamp') }.map do |result|
          {
            level: result.fetch('level'),
            createdTimeStamp: Time.zone.parse(result.fetch('createdTimeStamp'))
          }.tap do |answer|
            answer[:notes] = result.fetch('notes') if result.key?('notes')
            answer.merge! sourceUser: result.fetch('sourceUser') if result.key?('sourceUser')
          end
        end
      end

      def inactivate(offender_no)
        route = "/complexity-of-need/offender-no/#{offender_no}/inactivate"

        begin
          client.put route, cache: false
        rescue Faraday::ResourceNotFound
          nil
        end
      end

    private

      def client
        host = Rails.configuration.complexity_api_host
        HmppsApi::Client.new("#{host}/v1")
      end
    end
  end
end
