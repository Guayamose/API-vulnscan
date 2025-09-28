class Organization < ApplicationRecord
  has_many :users
  validates :slug, presence: true, uniqueness: true
end
