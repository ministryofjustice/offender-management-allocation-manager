module Ndelius
  class Api
    include Singleton

    class << self
      delegate :get_record, to: :instance
      delegate :get_records, to: :instance
    end

    def get_record(nomis_id)
      FakeRecord.generate(nomis_id)
    end

    def get_records(nomis_ids)
      nomis_ids.each_with_object({}) do |id, hash|
        hash[id] = FakeRecord.generate(id)
      end
    end
  end
end
