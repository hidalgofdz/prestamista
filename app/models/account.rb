class Account < ApplicationRecord
  has_many :users
  has_many :borrowers
  has_many :loans
  has_many :payments

  validates :name, presence: true
end
