require 'rails_helper'

RSpec.describe Nomis::ApiDeserialiser do
  let!(:memory_model_class) do
    Class.new do
      include MemoryModel
      attribute :foo, :string
    end
  end

  let(:payload) do
    { 'foo' => 'bar', 'unknown_attribute' => 'boom' }
  end

  subject { model.new(payload) }

  it 'will serialise a payload with unknown attributes', :raven_intercept_exception do
    expect(described_class.new.deserialise(memory_model_class, payload)).to have_attributes foo: 'bar'
  end
end
