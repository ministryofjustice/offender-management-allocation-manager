class CreateOffenderEmailTypesEnum < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
    CREATE TYPE offender_email_type AS ENUM (
      'upcoming_handover_window', 
      'handover_date',
      'com_allocation_overdue'
    );
    SQL
  end

  def down
    execute <<-SQL
    DROP type offender_email_type;
    SQL
  end
end
