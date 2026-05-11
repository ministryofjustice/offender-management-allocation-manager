# frozen_string_literal: true

module Timeline
  class VloHistory < BaseHistoryPresenter
    delegate :created_at, :event, to: :@version

    def initialize(version)
      super()
      @version = version
    end

    def to_partial_path
      "case_history/vlo/#{event}"
    end

    def created_by_name
      paper_trail_created_by_name(@version)
    end
  end
end
