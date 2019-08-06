class DeliusDataService
  def self.upsert(record)
    # store jobs list so that they
    # are only triggered after the transaction commits
    # otherwise we have a race condition where job can run against old data.
    jobs_to_run = []
    DeliusData.transaction do
      jobs_to_run = update_record(record)
    end
    jobs_to_run.each do |noms_no|
      ProcessDeliusDataJob.perform_later noms_no
    end
    jobs_to_run.any?
  end

private

  def self.update_record(record)
    jobs = []
    DeliusData.find_or_initialize_by(crn: record[:crn]).tap do |delius_data|
      if delius_data.new_record?
        delius_data.update!(record.without(:crn))
        jobs << record[:noms_no]
      else
        delius_data.assign_attributes record.without(:crn)
        jobs += process_changes(delius_data)
      end
    end
    jobs
  end

  def self.process_changes(delius_data)
    jobs = []
    if delius_data.changed?
      if delius_data.noms_no_changed?
        jobs << delius_data.noms_no_was
      end
      delius_data.save!
      jobs << delius_data.noms_no
    end
    jobs
  end
end
