class Borrower < ApplicationRecord
  belongs_to :account
  has_many :loans

  validates :name, presence: true
  validates :phone, presence: true
end
