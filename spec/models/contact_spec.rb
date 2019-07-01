require 'rails_helper'

RSpec.describe Contact, type: :model do
  it { Contact.new('message').validates_presence_of(:more_detail) }
end
