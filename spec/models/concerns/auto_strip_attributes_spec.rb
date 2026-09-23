# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoStripAttributes, type: :model do
  let(:test_model_class) do
    Class.new(ApplicationRecord) do
      self.table_name = 'local_delivery_units'
      include AutoStripAttributes
      auto_strip :code, :name
    end
  end

  it 'strips whitespace from specified attributes' do
    instance = test_model_class.new(code: '  TEST  ', name: '  Name  ')
    instance.valid?
    expect(instance.code).to eq('TEST')
    expect(instance.name).to eq('Name')
  end

  it 'handles nil values' do
    instance = test_model_class.new(code: nil, name: nil)
    expect { instance.valid? }.not_to raise_error
    expect(instance.code).to be_nil
    expect(instance.name).to be_nil
  end

  it 'only strips specified attributes' do
    instance = test_model_class.new(code: '  TEST  ', name: '  Name  ', enabled: true)
    instance.valid?
    expect(instance.code).to eq('TEST')
    expect(instance.name).to eq('Name')
  end
end
