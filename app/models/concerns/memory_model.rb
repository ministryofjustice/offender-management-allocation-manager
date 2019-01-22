require 'active_record'
require 'active_record/model_schema'
require 'active_record/attribute_decorators'

module MemoryModel
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks
    include ActiveRecord::AttributeDecorators
    include ActiveRecord::ModelSchema
    include ActiveRecord::AttributeMethods::Serialization
  end
end
