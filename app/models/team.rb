class Team < ApplicationRecord
  validates :name, :code, presence: true
end
