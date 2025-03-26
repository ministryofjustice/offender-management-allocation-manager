# Needed because we are pointing new kotlin service to
# the same database as the rails app, and we don't want
# the flyway stuff showing up in the structure.sql file
#
ActiveRecord::SchemaDumper.ignore_tables += [
  'flyway_schema_history',
]
