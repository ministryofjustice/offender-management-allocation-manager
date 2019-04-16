# frozen_string_literal: true

module Nomis
  module Custody
    class ImageApi
      extend CustodyApi

      def self.image_data(offender_no)
        route = "/custodyapi/api/offenders/nomsId/#{offender_no}/images"
        response = custody_client.get(route)
        image_id = most_recent_image(response)

        route =
          "/custodyapi/api/offenders/nomsId/#{offender_no}/images/#{image_id}/thumbnail"
        custody_client.raw_get(route)
      end

    private

      def self.most_recent_image(images)
        active_images = images.select { |record|
          record['activeFlag'] == true
        }

        most_recent =
          active_images.sort_by { |record| record['captureDateTime'] }.reverse.first
        most_recent['offenderImageId']
      end
    end
  end
end
