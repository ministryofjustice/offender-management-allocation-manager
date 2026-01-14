# frozen_string_literal: true

class ImportAllocationVersions
  FROM_DATE = Time.zone.local(2019, 1, 1)
  BATCH_SIZE = 5_000

  attr_reader :offset_id

  def initialize(offset_id: nil)
    @offset_id = (offset_id || ENV.fetch('OFFSET_ID', 1)).to_i
  end

  def call
    log("Starting with offset ID #{offset_id}...")

    papertrail_versions = PaperTrail::Version.where(item_type: 'AllocationHistory', event: 'update')
    create_counter = 0
    batch_counter = 0

    papertrail_versions.select(:id, :item_id, :whodunnit, :created_at, :object)
                       .in_batches(
                         of: BATCH_SIZE, start: [FROM_DATE, offset_id],
                         cursor: [:created_at, :id], order: [:asc, :asc]
                       ) do |relation|
      rows = relation.map do |version|
        AllocationHistoryVersion.attrs_from_papertrail(version)
      end

      ids = AllocationHistoryVersion.insert_all(rows)
      create_counter += ids.count
      batch_counter += 1

      log("Processed batch #{batch_counter} (#{create_counter} total records)") if batch_counter % 50 == 0
    end

    log("Finished import. Offset was ID #{offset_id}. Total imported versions: #{create_counter}")
    log("Last PaperTrail record ID: #{papertrail_versions.last.id}")
  end

private

  def log(msg)
    logger.info("[#{self.class}] #{msg}")
  end

  def logger
    @logger ||= Logger.new($stdout)
  end
end
