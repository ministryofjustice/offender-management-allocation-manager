# frozen_string_literal: true

class AddWelshFlagToLdu < ActiveRecord::Migration[6.0]
  def change
    change_table :local_divisional_units do |t|
      t.boolean :in_wales, default: false
    end

    LocalDivisionalUnit.where('code like ?', 'WPT%').update_all(in_wales: true)
    LocalDivisionalUnit.where('code like ?', 'N03%').update_all(in_wales: true)
  end
end
