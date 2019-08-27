class FeedbackSubmission < ApplicationRecord
  validates :body, presence: true
  validates :email_address, presence: true
  validates :name, presence: true
end