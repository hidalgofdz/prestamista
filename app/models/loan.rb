class Loan < ApplicationRecord
  belongs_to :account
  belongs_to :borrower
  has_many :payments, dependent: :restrict_with_error

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :annual_interest_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :term_months, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :start_date, presence: true

  before_validation :set_start_date

  def monthly_payment
    rate = monthly_rate
    return amount / term_months if rate.zero?

    amount * (rate * (1 + rate)**term_months) / ((1 + rate)**term_months - 1)
  end

  def end_date
    start_date >> term_months
  end

  def remaining_balance(excluding: nil)
    paid_principal = payments.where.not(id: excluding&.id).sum(:principal_applied)
    amount - paid_principal
  end

  def interest_due_on(date, excluding: nil)
    period_start = period_start_for(date)
    balance = remaining_balance(excluding: excluding)
    period_interest = balance * monthly_rate
    already_paid = payments
      .where.not(id: excluding&.id)
      .where(date: period_start..period_end_for(period_start))
      .sum(:interest_applied)
    [ period_interest - already_paid, 0 ].max
  end

  def next_payment_date
    return nil if paid_off?

    (1..term_months).each do |month|
      due_date = start_date >> month
      period_start = month == 1 ? start_date : (start_date >> (month - 1)) + 1.day
      period_payments = payments.where(date: period_start..due_date).sum(:amount)

      if period_payments < monthly_payment
        return due_date
      end
    end

    nil
  end

  def overdue?
    due = next_payment_date
    due.present? && due < Date.current
  end

  def paid_off?
    remaining_balance <= 0
  end

  private
  def monthly_rate
    annual_interest_rate / 100 / 12
  end

  def set_start_date
    self.start_date ||= Date.current
  end

  def period_start_for(date)
    months_elapsed = ((date.year - start_date.year) * 12) + (date.month - start_date.month)
    months_elapsed = [ months_elapsed, 0 ].max
    start_date >> months_elapsed
  end

  def period_end_for(period_start)
    (period_start >> 1) - 1
  end
end
