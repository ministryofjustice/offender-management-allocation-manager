# frozen_string_literal: true

class VictimLiaisonOfficer < ApplicationRecord
  auto_strip_attributes :email
  # Other version fields (user_first_name and user_last_name) filled in by controller
  has_paper_trail meta: { nomis_offender_id: :nomis_id_for_paper_trail }

  before_validation do |vlo|
    vlo.offender = vlo.case_information.offender if vlo.case_information.present?
  end

  belongs_to :case_information
  belongs_to :offender, foreign_key: :nomis_offender_id, inverse_of: :victim_liaison_officers

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
