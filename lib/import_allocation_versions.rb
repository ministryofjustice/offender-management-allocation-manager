# frozen_string_literal: true

class ImportAllocationVersions
  attr_reader :offset_id, :batch_size

  def initialize(offset_id: nil, batch_size: nil)
    @offset_id = (offset_id || ENV.fetch('OFFSET_ID', 1)).to_i
    @batch_size = (batch_size || ENV.fetch('BATCH_SIZE', 2_000)).to_i
  end

  def call
    papertrail_versions = PaperTrail::Version.where(item_type: 'AllocationHistory', event: 'update')
    create_counter = 0
    batch_counter = 0

    log("Current PaperTrail versions: #{papertrail_versions.count}. Last ID: #{papertrail_versions.last.id}")
    log("Starting with offset ID #{offset_id} and batch size #{batch_size}...")

    papertrail_versions.select(:id, :item_id, :whodunnit, :created_at, :object)
                       .in_batches(of: batch_size, start: offset_id, order: :asc) do |relation|
      rows = relation.map do |version|
        AllocationHistoryVersion.attrs_from_papertrail(version)
      end

      AllocationHistoryVersion.insert_all(rows)
      create_counter += relation.size
      batch_counter += 1

      log("Processed batch #{batch_counter} (#{create_counter} total records)") if batch_counter % 10 == 0
    end

    log("Finished import. Offset was ID #{offset_id}. Total imported versions: #{create_counter}")
    log("Last PaperTrail record ID: #{papertrail_versions.last.id}")
  end

private

  # Using puts, as logger does not seem to output anything until the job exits
  def log(msg)
    puts "#{Time.current.strftime('%Y-%m-%d %H:%M:%S.%3N')} [#{self.class}] #{msg}"
  end
end
