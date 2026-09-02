# frozen_string_literal: true

class MergeHistory < BaseHistoryPresenter
  attr_reader :old_nomis_id, :new_nomis_id, :created_at

  def initialize(nomis_id_merge)
    super()

    @old_nomis_id = nomis_id_merge.old_nomis_id
    @new_nomis_id = nomis_id_merge.new_nomis_id
    @created_at = nomis_id_merge.created_at
  end

  def created_by_name
    'System'
  end

  def to_partial_path
    'case_history/merge/merge'
  end
end
