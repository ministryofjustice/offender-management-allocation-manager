namespace :batch_push_pom_to_delius do
  desc 'batch push pom to delius job'
  task populate_delius: :environment do
    Allocation.where.not(primary_pom_nomis_id: nil).find_each do |allocation|
      PushPomToDeliusJob.perform_later(allocation)
    end
  end
end
