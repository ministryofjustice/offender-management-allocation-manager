# frozen_string_literal: true

require_relative '../application_service'

module POM
  class GetPomsForPrison < ApplicationService
    attr_reader :prison

    def initialize(prison)
      @prison = prison
    end

    def call
      poms = Nomis::Elite2::PrisonOffenderManagerApi.list(@prison)
      pom_details = PomDetail.where(nomis_staff_id: poms.map(&:staff_id).map(&:to_i))

      poms.map { |pom|
        detail = get_pom_detail(pom_details, pom.staff_id.to_i)
        pom.add_detail(detail, prison)
        pom
      }.compact
    end

  private

    def get_pom_detail(pom_details, staff_id)
      pom_details.detect { |pd| pd.nomis_staff_id == staff_id } ||
        PomDetail.create!(nomis_staff_id: staff_id,
                          working_pattern: 0.0,
                          status: 'active')
    end
  end
end
