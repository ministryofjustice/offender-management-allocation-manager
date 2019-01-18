module Ndelius
  class Api
    include Singleton

    class << self
      delegate :get_record, to: :instance
    end

    def get_record(nomis_id)
      FakeRecord.generate(nomis_id)
    end
  end
end
