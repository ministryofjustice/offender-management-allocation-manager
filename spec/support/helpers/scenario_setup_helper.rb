require_relative "scenario_setup_helper/handover_setup"
require_relative "scenario_setup_helper/mpc_offender_setup"

module ScenarioSetupHelper
  extend ActiveSupport::Concern

  included do
    include HandoverSetup
    include MpcOffenderSetup
  end
end
