# frozen_string_literal: true

require 'rake'
require 'cnl_deactivation'

namespace :deactivate_cnls do
  desc 'Display NOMIS IDs of offenders needing de-activation of complexity of needs level but dont actually de-activate them'
  task display: :environment do
    CnlDeactivation.new(dry_run: true).call
  end

  desc 'De-activate complexity of needs level for offenders in womens prisons with no sentence'
  task process: :environment do
    CnlDeactivation.new(dry_run: false).call
  end
end