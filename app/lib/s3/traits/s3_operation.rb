module S3
  module Traits
    module S3Operation
      class S3Error < StandardError; end

    private

      def client
        @client ||= Aws::S3::Client.new(
          **{
            endpoint:
          }.merge(default_client_cfg).compact_blank
        )
      end

      def resource
        @resource ||= Aws::S3::Resource.new(client:)
      end

      def bucket
        resource.bucket(bucket_name)
      end

      def object
        bucket.object(object_key)
      end

      def log(details)
        if $ERROR_INFO
          Rails.logger.error("[#{self.class.name}] #{details.merge(error: $ERROR_INFO.message).to_json}")
        else
          Rails.logger.info("[#{self.class.name}] #{details.to_json}")
        end
      end

      def default_client_cfg
        {
          force_path_style: true,
          retry_limit: 3,
          retry_backoff: -> { sleep(5) }
        }.freeze
      end

      def bucket_name
        ENV.fetch('S3_BUCKET_NAME', nil)
      end

      # Endpoint is only used to fake a local S3 service
      def endpoint
        ENV.fetch('AWS_ENDPOINT_URL', nil)
      end
    end
  end
end
