# frozen_string_literal: true

require_relative '../application_service'

module POMService
  class GetPom < ApplicationService
    attr_reader :prison, :staff_id

    def initialize(prison, staff_id)
      @prison = prison
      @staff_id = staff_id
    end

    def call
      poms_list = GetPomsForPrison.call(@prison)
      return nil if poms_list.blank?

      @pom = poms_list.select { |p| p.staff_id == @staff_id.to_i }.first
      return nil if @pom.blank?

      @pom.emails = POMService::GetPomEmails.call(@pom.staff_id)
      @pom
    end
  end
end
