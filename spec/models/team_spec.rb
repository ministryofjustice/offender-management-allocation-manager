require 'rails_helper'

RSpec.describe Team, type: :model do
  it {
    expect(subject).to validate_presence_of :name
    expect(subject).to validate_presence_of :code
  }
end
