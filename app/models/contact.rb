class Contact
  include ActiveModel::Validations

  attr_accessor :more_detail
  validates :more_detail, presence: true

  def initialize(message)
    @more_detail = message
  end
end
