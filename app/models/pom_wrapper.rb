# frozen_string_literal: true

#
# The return value from get_list_of_poms - a combo of PomDetails and PrisonOffenderManager from the API
class PomWrapper < SimpleDelegator
  delegate :email_address, :full_name, :full_name_ordered, :position_description, :first_name, :last_name,
           :probation_officer?, :prison_officer?, :position, :staff_id, :agency_id, to: :@pom

  def initialize(pom, pom_detail)
    @pom = pom

    # everything else delegated to `pom_detail`
    super(
      pom_detail
    )
  end
end
