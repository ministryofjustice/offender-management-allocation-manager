require 'rails_helper'

RSpec.describe OverrideForm, type: :model do
  let!(:reason) do
    "consectetur a eraconsectetur a erat nam at lectus urna duis convallis
    convallis tellus id interdum velit laoreet id donec ultrices tincidunt arcu non sodales neque sodales ut etiam"
  end

  it {
    expect(subject).to validate_presence_of(:override_reasons).with_message('Select one or more reasons for not accepting the recommendation')
  }

  it {
    o = described_class.new(override_reasons: ['other'])
    expect(o.valid?).to be false
    expect(o.errors[:more_detail].count).to eq(1)
    expect(o.errors[:more_detail].first).to eq('Please provide extra detail when Other is selected')
  }

  it {
    o = described_class.new(override_reasons: ['other'], more_detail: reason)
    expect(o.valid?).to be false
    expect(o.errors[:more_detail].count).to eq(1)
    expect(o.errors[:more_detail].first).to eq('This reason cannot be more than 175 characters')
  }

  it {
    o = described_class.new(override_reasons: ['cats'])
    expect(o.valid?).to be true
    expect(o.errors[:more_detail].count).to eq(0)
  }

  it {
    o = described_class.new(override_reasons: ['suitability'])
    expect(o.valid?).to be false
    expect(o.errors[:suitability_detail].count).to eq(1)
    expect(o.errors[:suitability_detail].first).to eq('Enter reason for allocating this POM')
  }

  it {
    o = described_class.new(override_reasons: ['suitability'], suitability_detail: reason)
    expect(o.valid?).to be false
    expect(o.errors[:suitability_detail].count).to eq(1)
    expect(o.errors[:suitability_detail].first).to eq('This reason cannot be more than 175 characters')
  }

  it {
    o = described_class.new(override_reasons: ['dogs'])
    expect(o.valid?).to be true
    expect(o.errors[:suitability_detail].count).to eq(0)
  }
end
