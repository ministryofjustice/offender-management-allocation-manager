module S3
  class List
    include Traits::S3Operation

    attr_accessor :prefix, :start_after

    def initialize(prefix: nil, start_after: nil)
      @prefix = prefix
      @start_after = start_after
    end

    def call
      objects = bucket.objects(prefix:, start_after:).map do |obj|
        {
          object_key: obj.key,
          size: obj.size,
          last_modified: obj.last_modified.iso8601,
        }
      end
    rescue StandardError => e
      raise S3Error, e
    ensure
      log(prefix:, start_after:, count: objects.try(:count))
    end
  end
end
