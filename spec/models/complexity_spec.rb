# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Complexity, type: :model do
  subject {
    described_class.new(level: "high",
                        reason: "Lorem ipsum")
  }

  it 'validates the presence of level, reason' do
    expect(subject).to be_valid :level
    expect(subject).to be_valid :reason
  end

  it "is not valid without a level" do
    subject.level = nil
    expect(subject).not_to be_valid
  end

  it "is not valid without a reason" do
    subject.reason = nil
    expect(subject).not_to be_valid
    expect(subject.errors.messages).to eq(reason: ["Enter the reason why the level has changed"])
  end
end
