class Hub < ApplicationRecord
  validates :hub_number, presence: true
  validates :name, presence: true
  validates :attendance, presence: true
end