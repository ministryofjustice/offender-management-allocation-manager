require 'rails_helper'

RSpec.describe Nomis::ApiDeserialiser do
  # rubocop:disable RSpec/LeakyConstantDeclaration
  class DeserialiseTest
    attr_accessor :foo, :string

    def self.from_json(payload)
      DeserialiseTest.new.tap { |obj|
        obj.foo = payload['foo']
      }
    end
  end

  class DeserialiseTestFail
  end
  # rubocop:enable RSpec/LeakyConstantDeclaration

  subject { model.from_json(payload) }

  let!(:memory_model_class) { DeserialiseTest }
  let!(:failing_memory_model_class) { DeserialiseTestFail }

  let(:payload) do
    { 'foo' => 'bar', 'unknown_attribute' => 'boom' }
  end


  it 'will serialise a payload with unknown attributes', :raven_intercept_exception do
    expect(described_class.new.deserialise(memory_model_class, payload)).to have_attributes foo: 'bar'
  end

  it 'fail for classes not implementing from_json', :raven_intercept_exception do
    expect(described_class.new.deserialise(failing_memory_model_class, payload)).to be_nil
  end
end
