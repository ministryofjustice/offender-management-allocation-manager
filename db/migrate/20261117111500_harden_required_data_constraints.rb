# frozen_string_literal: true

class HardenRequiredDataConstraints < ActiveRecord::Migration[8.1]
  def change
    change_table :case_information, bulk: true do |t|
      t.change_null :created_at, false
      t.change_null :updated_at, false
    end

    change_table :handover_progress_checklists, bulk: true do |t|
      t.change_null :created_at, false
      t.change_null :updated_at, false
    end

    change_table :pom_details, bulk: true do |t|
      t.change_null :nomis_staff_id, false
      t.change_null :prison_code, false
      t.change_null :working_pattern, false
      t.change_null :status, false
    end

    change_table :parole_reviews, bulk: true do |t|
      t.change_null :review_id, false
      t.change_null :nomis_offender_id, false
    end
  end
end
