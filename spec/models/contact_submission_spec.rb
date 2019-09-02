require 'rails_helper'

RSpec.describe ContactSubmission, type: :model do
  it { described_class.new('message').validates_presence_of(:more_detail) }
end
