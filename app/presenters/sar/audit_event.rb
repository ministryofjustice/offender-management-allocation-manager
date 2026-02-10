# frozen_string_literal: true

module Sar
  class AuditEvent < BaseSarPresenter
    class << self
      def omitted_attributes
        [:username, :user_human_name, :data]
      end
    end
  end
end
