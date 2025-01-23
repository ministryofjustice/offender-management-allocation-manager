# frozen_string_literal: true

module Sar
  class BaseSarPresenter < SimpleDelegator
    include ActiveModel::Serializers::JSON

    class << self
      def omitted_attributes
        []
      end

      def humanized_attributes
        []
      end

      def additional_methods
        []
      end
    end

    def serializable_hash(_options = nil)
      super(
        except: omitted_attributes + generic_omitted_attributes,
        methods: additional_methods,
      )
    end

    def as_json(options = nil)
      jsonify_hash(super(options))
    end

  private

    def generic_omitted_attributes
      [:id, :nomis_offender_id, :crn]
    end

    def omitted_attributes
      self.class.omitted_attributes
    end

    def humanized_attributes
      self.class.humanized_attributes
    end

    def additional_methods
      self.class.additional_methods
    end

    def humanize(attr, value)
      I18n.t(value, default: value.try(:humanize), scope: [self.class.name.underscore, attr])
    end

    def jsonify_hash(hash)
      humanized_attributes.map(&:to_s).each do |attr|
        hash[attr.to_s] = humanize(attr, hash[attr])
      end

      hash.deep_transform_keys! { |key| key.camelcase(:lower) }
    end
  end
end
