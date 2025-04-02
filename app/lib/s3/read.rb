module S3
  class Read
    include Traits::S3Operation

    attr_accessor :object_key

    def initialize(object_key:)
      @object_key = object_key
    end

    def call
      object_output = object.get
      object_output.body.read
    rescue StandardError => e
      raise S3Error, e
    ensure
      log(
        object_key:,
        version_id: object_output.try(:version_id),
        size: object_output.try(:content_length),
      )
    end
  end
end
