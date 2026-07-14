# frozen_string_literal: true

module Sar
  class HandoverProgressChecklist < BaseSarPresenter
    class << self
      def omitted_attributes
        [:handover_episode_started_at]
      end
    end
  end
end
