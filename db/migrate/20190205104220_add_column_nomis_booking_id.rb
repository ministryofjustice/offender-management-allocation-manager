class AddColumnNomisBookingId < ActiveRecord::Migration[5.2]
  def up
    add_column :allocations, :nomis_booking_id, :int
  end

  def down
    remove_column :allocations, :nomis_booking_id
  end
end
