# frozen_string_literal: true

module AutoStripAttributes
  extend ActiveSupport::Concern

  module ClassMethods
    def auto_strip(*attributes)
      before_validation do
        attributes.each { |attr| send("#{attr}=", send(attr)&.strip) }
      end
    end
  end
end
