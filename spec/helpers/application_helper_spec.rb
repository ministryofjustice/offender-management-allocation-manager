require 'rails_helper'

RSpec.describe ApplicationHelper do
  it "can choose the correct responsibility label" do
    expect(responsibility_label('Probation')).to eq('Community')
    expect(responsibility_label('Prison')).to eq('Prison')
  end
end