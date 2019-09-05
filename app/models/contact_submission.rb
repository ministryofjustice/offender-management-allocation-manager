class ContactSubmission < ApplicationRecord
  validates :email_address, presence: {
      message: 'Email address is required'
  }

  validates :name, presence: {
      message: 'Your name is required'
  }

  validates :prison, presence: {
      message: 'The prison name is required'
  }

  validates :role, presence: {
      message: 'Your role is required'
  }
  
  validates :body, presence: {
      message: 'A message is required'
  }
end
