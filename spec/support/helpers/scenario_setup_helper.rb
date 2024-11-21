require_relative "scenario_setup_helper/handover_setup"

module ScenarioSetupHelper
  extend ActiveSupport::Concern
  
  included do
    include HandoverSetup
  end
end