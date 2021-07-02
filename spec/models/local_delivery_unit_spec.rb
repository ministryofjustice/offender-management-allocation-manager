# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LocalDeliveryUnit, type: :model do
  it 'has a valid factory' do
    expect(build(:local_delivery_unit)).to be_valid
  end

  it 'strips whitespace from properties before validation so they are valid' do
    expect(build(:local_delivery_unit, email_address: '  test@example.com ')).to be_valid
    expect(build(:local_delivery_unit, code: '  T34234 ')).to be_valid
  end

  context 'with an existing model' do
    before do
      create(:local_delivery_unit)
    end

    it 'keeps codes unique' do
      expect(subject).to validate_uniqueness_of(:code)
    end

    it 'validates country' do
      expect(subject).to validate_inclusion_of(:country).in_array(['England', "Wales"])
    end
  end

  describe '"enabled" scope' do
    let!(:enabled_ldus) { create_list(:local_delivery_unit, 5) }
    let!(:disabled_ldus) { create_list(:local_delivery_unit, 5, :disabled) }

    it 'only retrieves enabled LDUs' do
      expect(described_class.enabled).to match_array(enabled_ldus)
    end
  end
end
