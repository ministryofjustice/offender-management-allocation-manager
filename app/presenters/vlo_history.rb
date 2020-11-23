# frozen_string_literal: true

class VloHistory
  delegate :created_at, :event, :prison, to: :@version

  def initialize(version)
    @version = version
  end

  def to_partial_path
    "vlo_#{event}"
  end

  def created_by_name
    if @version.whodunnit
      "#{@version.user_last_name}, #{@version.user_first_name}"
    end
  end
end
