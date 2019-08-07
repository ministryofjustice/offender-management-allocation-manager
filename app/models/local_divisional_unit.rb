class LocalDivisionalUnit < ApplicationRecord
  validates :code, :name, presence: true
end
