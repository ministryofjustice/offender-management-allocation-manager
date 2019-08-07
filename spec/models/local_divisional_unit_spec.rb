require 'rails_helper'

RSpec.describe LocalDivisionalUnit, type: :model do
  it {
    expect(subject).to validate_presence_of :name
    expect(subject).to validate_presence_of :code
  }
end
