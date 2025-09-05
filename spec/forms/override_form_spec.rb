describe OverrideForm do
  it 'a reason for overriding must be given' do
    override = described_class.new(override_reasons: nil)
    expect(override).not_to be_valid
    expect(override.errors[:override_reasons]).to match_array(['Select one or more reasons for not accepting the recommendation'])
  end

  it 'more details must be given when overriding due to another reason' do
    override = described_class.new(override_reasons: ['other'])
    expect(override).not_to be_valid
    expect(override.errors[:more_detail]).to match_array(['Please provide extra detail when Other is selected'])
  end

  it 'other reason details can be a maximum of 175 characters long' do
    too_long_reason = 'a' * 176
    override = described_class.new(override_reasons: ['other'], more_detail: too_long_reason)
    expect(override).not_to be_valid
    expect(override.errors[:more_detail]).to match_array(['This reason cannot be more than 175 characters'])
  end

  it 'more details must be given when overriding due to suitability' do
    override = described_class.new(override_reasons: ['suitability'])
    expect(override).not_to be_valid
    expect(override.errors[:suitability_detail]).to match_array(['Enter reason for allocating this POM'])
  end

  it 'suitability details can be a maximum of 175 characters long' do
    too_long_reason = 'a' * 176
    override = described_class.new(override_reasons: ['suitability'], suitability_detail: too_long_reason)
    expect(override).not_to be_valid
    expect(override.errors[:suitability_detail]).to match_array(['This reason cannot be more than 175 characters'])
  end

  it 'any other override reason but suitability and other is fine and requires no extra details' do
    override = described_class.new(override_reasons: ['dogs'])
    expect(override).to be_valid
  end
end
