class AddSentHandoverReportToHandoverProgressChecklist < ActiveRecord::Migration[6.1]
  def change
    change_table :handover_progress_checklists do |t|
      t.boolean :sent_handover_report, null: false, default: false
    end
  end
end
