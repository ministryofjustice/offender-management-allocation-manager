# frozen_string_literal: true

class VictimLiaisonOfficer < ApplicationRecord
  auto_strip_attributes :email
  # Other version fields (user_first_name and user_last_name) filled in by controller
  has_paper_trail meta: { nomis_offender_id: :nomis_id_for_paper_trail }

  belongs_to :case_information
  validates_presence_of :last_name, :first_name

  validates :email, presence: true, 'valid_email_2/email': true

  def full_name
    "#{last_name}, #{first_name}"
  end

private

  def nomis_id_for_paper_trail
    case_information.nomis_offender_id
  end
end
