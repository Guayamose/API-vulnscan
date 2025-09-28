class User < ApplicationRecord
  belongs_to :organization
  has_secure_password
  enum :role, { developer: 'developer', admin: 'admin' }
  validates :email, presence: true, uniqueness: true
end

