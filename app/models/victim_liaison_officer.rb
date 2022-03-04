# frozen_string_literal: true

class VictimLiaisonOfficer < ApplicationRecord
  auto_strip_attributes :email
  # Other version fields (user_first_name and user_last_name) filled in by controller
  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }

  belongs_to :offender, foreign_key: :nomis_offender_id, inverse_of: :victim_liaison_officers

  validates :last_name, :first_name, presence: true

  validates :email, presence: true, 'valid_email_2/email': true

  def full_name
    "#{last_name}, #{first_name}"
  end
end
