require 'csv'

class ParoleDataImportService
  S3_OBJECT_PREFIX = 'PPUD_MPC'.freeze

  CSV_HEADINGS = {
    title: 'TITLE',
    nomis_id: 'NOMIS ID',
    prison_no: 'Offender Prison Number',
    sentence_type: 'Sentence Type',
    sentence_date: 'Date Of Sentence',
    tariff_exp: 'Tariff Expiry Date',
    review_date: 'Review Date',
    review_id: 'Review ID',
    review_milestone_date_id: 'Review Milestone Date ID',
    review_type: 'Review Type',
    review_status: 'Review Status',
    curr_target_date: 'Current Target Date (Review)',
    ms13_target_date: 'MS 13 Target Date',
    ms13_completion_date: 'MS 13 Completion Date',
    final_result: 'Final Result (Review)'
  }.freeze

  def initialize(log_prefix: 'service=parole_data_import_service', single_day_snapshot: true)
    @log_prefix = log_prefix
    @single_day_snapshot = single_day_snapshot
    @import_id = SecureRandom.uuid
    @csv_row_import_count = 0
    @csv_row_count = 0
    @s3_object_key = nil
  end

  def import_with_catchup(date)
    latest_imported_date = ParoleReviewImport.maximum(:snapshot_date)

    dates_to_import = if latest_imported_date.nil?
                        date
                      elsif latest_imported_date < date
                        (latest_imported_date + 1..date)
                      end

    dates_to_import.to_a.each do |dt|
      Rails.logger.info(format_log("Importing date #{dt}.", dt))
      import_from_s3_bucket(dt)
    end

    [@csv_row_import_count, @csv_row_count]
  end

  def import_from_s3_bucket(date)
    prefix = [S3_OBJECT_PREFIX, date.strftime('%Y%m%d')].join('_')
    csv_files = S3::List.new(prefix:).call

    if csv_files.empty?
      Rails.logger.warn(format_log("No files found with prefix #{prefix}", date))
    else
      # In the scenario multiple files for the same prefix (date)
      # are found, we only need to process the most recent one
      @s3_object_key = csv_files.last[:object_key]

      Rails.logger.info(
        format_log("Found #{csv_files.size} files with prefix #{prefix}. Importing #{@s3_object_key}", date)
      )

      csv_content = S3::Read.new(object_key: @s3_object_key).call
      import_from_rows(CSV.new(csv_content, headers: true), date)
    end
  end

  def self.purge
    ParoleReviewImport.to_purge.delete_all
  end

private

  def import_from_rows(csv_rows, date)
    @csv_row_count = 0
    @csv_row_import_count = 0

    ApplicationRecord.transaction do # To improve performance. The index can cause drag
      csv_rows.each do |csv_row|
        @csv_row_count += 1
        import_row(csv_row, date)
      end
    end
  end

  def import_row(csv_row, date)
    imported_row = ParoleReviewImport.new

    CSV_HEADINGS.each do |attribute_name, col_heading|
      imported_row.send("#{attribute_name}=", csv_row[col_heading]&.strip)
    end

    imported_row.snapshot_date = date
    imported_row.row_number = @csv_row_count
    imported_row.import_id = @import_id
    imported_row.s3_object_key = @s3_object_key
    imported_row.single_day_snapshot = @single_day_snapshot
    imported_row.save!
    @csv_row_import_count += 1
  rescue StandardError => e
    Rails.logger.error(format_log("CSV row with Review ID: #{csv_row[CSV_HEADINGS[:review_id]]} had error: #{e}", date))
  end

  def format_log(message, date)
    prefix = [
      @log_prefix,
      "snapshot_date=#{date}",
      "import_id=#{@import_id}"
    ].compact.join(',')

    "#{prefix}|#{message}"
  end
end
