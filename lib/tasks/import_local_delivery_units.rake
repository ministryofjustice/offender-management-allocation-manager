# frozen_string_literal: true

require 'rake'

namespace :import do
  namespace :local_delivery_units do
    desc 'Retrieves LDUs from Mailbox Register and shows potential changes, without persisting them'
    task dry_run: :environment do
      ImportLocalDeliveryUnits.new(dry_run: true).call
    end

    desc 'Retrieves LDUs from Mailbox Register and updates our DB table'
    task process: :environment do
      ImportLocalDeliveryUnits.new(dry_run: false).call
    end
  end
end
