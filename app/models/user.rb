class User < ApplicationRecord
  belongs_to :account
  has_many :sessions, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  generates_token_for :magic_link, expires_in: 15.minutes

  def self.register(name:, email:)
    account = Account.new(name: name)
    user = account.users.build(name: name, email: email)
    account.save!
    user
  end
end
