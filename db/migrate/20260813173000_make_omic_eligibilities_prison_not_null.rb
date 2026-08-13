# frozen_string_literal: true

class MakeOmicEligibilitiesPrisonNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :omic_eligibilities, :prison, false
  end
end
