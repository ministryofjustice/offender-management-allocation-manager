# This is the old 'Contact Us' plumbing - these records would be sent off to Zendesk after being stored in the DB.
# Model being kept around so we can query the old contact us messages should we need to, but can be removed once that
# need is no longer present
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

  validates :job_type, presence: {
    message: 'Your role is required'
  }

  validates :message, presence: {
    message: 'A message is required'
  }
end
