class DropFlywaySchemaTable < ActiveRecord::Migration[8.1]
  def up
    drop_table :flyway_schema_history, if_exists: true
    drop_table :flyway_schema_migrations, if_exists: true
  end
end
