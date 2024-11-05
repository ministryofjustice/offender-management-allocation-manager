# frozen_string_literal: true

#
# The return value from poms - a combo of PomDetails and PrisonOffenderManager from the API
class PomWrapper
  delegate :email_address, :full_name, :full_name_ordered, :position_description, :first_name, :last_name,
           :probation_officer?, :prison_officer?, :staff_id, :agency_id, to: :@pom
  delegate :status, :working_pattern, :allocations, to: :@pom_detail

  def initialize(pom, pom_detail)
    @pom = pom
    @pom_detail = pom_detail
  end
end
