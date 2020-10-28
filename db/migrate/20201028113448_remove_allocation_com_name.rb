# frozen_string_literal: true

class RemoveAllocationComName < ActiveRecord::Migration[6.0]
  def change
    remove_column :allocations, :com_name, :string
  end
end
