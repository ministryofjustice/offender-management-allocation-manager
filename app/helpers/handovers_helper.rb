module HandoversHelper
  def upcoming_prison_handovers_path_shortcut
    prison_id = params.fetch(:prison_id)
    upcoming_prison_handovers_path(prison_id: prison_id, new_handover: NEW_HANDOVER_TOKEN)
  end
end
