class RemoveAllocationBookingId < ActiveRecord::Migration[6.0]
  def change
    remove_column :allocations, :nomis_booking_id, :integer
  end
end
