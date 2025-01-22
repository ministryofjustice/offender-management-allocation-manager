# frozen_string_literal: true

module Sar
  class BaseSarPresenter < SimpleDelegator
    include ActiveModel::Serializers::JSON

    class << self
      def omitted_attributes
        []
      end

      def additional_methods
        []
      end
    end

    # Used by `serializable_hash`
    def attributes
      __getobj__ ? super : {}
    end

    def serializable_hash(_options = nil)
      super(
        except: self.class.omitted_attributes + generic_omitted_attributes,
        methods: self.class.additional_methods,
      )
    end

    def as_json(options = nil)
      jsonify_hash(super(options))
    end

  private

    def generic_omitted_attributes
      [:id, :nomis_offender_id, :crn]
    end

    def jsonify_hash(hash)
      hash.tap do |attrs|
        attrs.deep_transform_keys! { |key| key.camelcase(:lower) }
      end
    end
  end
end
