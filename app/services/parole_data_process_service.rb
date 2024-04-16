class ParoleDataProcessService
  def self.process
    @processed_on = Time.zone.today
    @results = {
      total_count: ParoleReviewImport.to_process.count,
      processed_count: 0,
      parole_reviews_created_count: 0,
      parole_reviews_updated_count: 0,
      blank_import_keys_count: 0,
      no_offender_count: 0,
      other_error_count: 0
    }

    snapshot_dates_to_process = ParoleReviewImport.to_process.pluck(:snapshot_date).uniq.sort
    log("Starting. #{@results[:total_count]} imports across #{snapshot_dates_to_process.size} snapshot dates to process")

    snapshot_dates_to_process.each do |snapshot_date|
      to_process = ParoleReviewImport.to_process.where(snapshot_date: snapshot_date).order(:row_number)
      log("Processing #{to_process.count} imports for #{snapshot_date}")

      ApplicationRecord.transaction do
        to_process.each { |import_row| build_parole_review(import_row) }
      end
    end

    log("Finished: #{format_results}")
    @results
  end

  def self.build_parole_review(import_row)
    if import_row.review_id.blank? || import_row.nomis_id.blank?
      @results[:blank_import_keys_count] += 1
    elsif Offender.find_by_nomis_offender_id(import_row.sanitized_nomis_id).nil?
      @results[:no_offender_count] += 1
      log('No MPC offender matches NOMIS ID', import_row_id: import_row.id, nomis_offender_id: import_row.sanitized_nomis_id)
    else
      begin
        record = ParoleReview.find_or_initialize_by(review_id: import_row.review_id, nomis_offender_id: import_row.sanitized_nomis_id)

        hearing_outcome_received_on = if record.hearing_outcome_received_on.present?
                                        record.hearing_outcome_received_on
                                      elsif !import_row.single_day_snapshot?
                                        nil
                                      elsif record.no_hearing_outcome? && !import_row.no_hearing_outcome?
                                        import_row.snapshot_date
                                      end

        record.target_hearing_date = import_row.curr_target_date
        record.custody_report_due = import_row.ms13_target_date
        record.review_status = import_row.review_status
        record.hearing_outcome_received_on = hearing_outcome_received_on
        record.hearing_outcome = import_row.final_result
        record.review_type = import_row.review_type

        if record.changed?
          record.id.present? ? @results[:parole_reviews_updated_count] += 1 : @results[:parole_reviews_created_count] += 1
          record.save
        end
      rescue StandardError => e
        @results[:other_error_count] += 1
        log("Error importing parole review: #{e}", import_row_id: import_row.id, nomis_offender_id: import_row.sanitized_nomis_id, level: :error)
      end
    end

    import_row.update(processed_on: @processed_on)
    @results[:processed_count] += 1
  end

private

  def self.format_results
    @results.map { |k, v| "#{k}: #{v}" }.join(', ')
  end

  def self.log(msg, import_row_id: nil, nomis_offender_id: nil, level: :info)
    prefix = ['service=parole_data_process_service']
    prefix << "nomis_offender_id=#{nomis_offender_id}" if nomis_offender_id
    prefix << "import_row_id=#{import_row_id}" if import_row_id

    Rails.logger.send(level, "#{prefix.join(',')}|#{msg}")
  end
end
