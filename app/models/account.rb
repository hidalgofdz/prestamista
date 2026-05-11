class Account < ApplicationRecord
  has_many :users
  has_many :borrowers
  has_many :loans

  validates :name, presence: true
end
