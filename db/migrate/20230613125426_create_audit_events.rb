class CreateAuditEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :audit_events, id: :uuid do |t|
      t.text :nomis_offender_id
      t.text :tags, array: true, null: false
      t.timestamp :published_at, null: false, precision: 6
      t.boolean :system_event, null: true
      t.text :username
      t.text :user_human_name
      t.jsonb :data, null: false

      t.timestamps null: false

      t.check_constraint <<-SQL, name: 'system_event_cannot_have_user_details'
        (system_event = true AND username IS NULL AND user_human_name IS NULL) OR
        (system_event = false)
      SQL
    end
  end
end
