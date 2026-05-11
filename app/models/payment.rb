class Payment < ApplicationRecord
  belongs_to :account, default: -> { loan.account }
  belongs_to :loan

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true

  before_validation :set_date
  before_validation :apply_to_interest_and_principal

  validate :amount_does_not_exceed_balance
  validate :date_not_in_future

  private
  def set_date
    self.date ||= Date.current
  end

  def apply_to_interest_and_principal
    return unless loan && amount.present? && amount > 0

    interest_due = loan.interest_due_on(date, excluding: self)
    self.interest_applied = [ amount, interest_due ].min
    self.principal_applied = amount - interest_applied
  end

  def amount_does_not_exceed_balance
    return unless loan && amount.present?

    if amount > loan.remaining_balance(excluding: self)
      errors.add(:amount, :exceeds_balance)
    end
  end

  def date_not_in_future
    return unless date.present?

    if date > Date.current
      errors.add(:date, :in_future)
    end
  end
end
