class Loan < ApplicationRecord
  belongs_to :account, default: -> { borrower.account }
  belongs_to :borrower, touch: true
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
    paid_principal = cached_payments(excluding: excluding).sum(&:principal_applied)
    amount - paid_principal
  end

  def interest_due_on(date, excluding: nil)
    period_start = period_start_for(date)
    balance = remaining_balance(excluding: excluding)
    period_interest = balance * monthly_rate
    already_paid = cached_payments(excluding: excluding)
      .select { |p| p.date >= period_start && p.date <= period_end_for(period_start) }
      .sum(&:interest_applied)
    [ period_interest - already_paid, 0 ].max
  end

  def next_payment_date
    return nil if paid_off?

    (1..term_months).each do |month|
      due_date = start_date >> month
      period_start = month == 1 ? start_date : (start_date >> (month - 1)) + 1.day
      period_payments = cached_payments.select { |p| p.date >= period_start && p.date <= due_date }

      if !period_covered?(period_payments)
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

  def recalculate_payments
    ordered = payments.reload.order(date: :asc, created_at: :asc).to_a
    running_balance = amount

    transaction do
      ordered.each do |payment|
        interest_due = interest_for_running_balance(payment, running_balance, ordered)
        payment.interest_applied = [ payment.amount, interest_due ].min
        payment.principal_applied = payment.amount - payment.interest_applied

        if payment.principal_applied > running_balance
          raise ActiveRecord::RecordInvalid.new(payment)
        end

        # update_columns bypasses validations intentionally — running amount_does_not_exceed_balance
        # against a mid-recalculation balance would produce spurious errors before the balance settles.
        payment.update_columns(interest_applied: payment.interest_applied, principal_applied: payment.principal_applied)
        running_balance -= payment.principal_applied
      end
    end
  end

  private
  def period_covered?(period_payments)
    if period_payments.empty?
      false
    elsif monthly_rate.zero?
      period_payments.sum(&:amount) >= monthly_payment
    else
      period_payments.sum(&:amount) >= monthly_payment &&
        period_payments.any? { |p| p.interest_applied > 0 }
    end
  end

  def cached_payments(excluding: nil)
    all = payments.load
    if excluding
      all.reject { |p| p.id == excluding.id }
    else
      all
    end
  end

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

  def interest_for_running_balance(payment, running_balance, ordered)
    period_start = period_start_for(payment.date)
    period_end = period_end_for(period_start)
    period_interest = running_balance * monthly_rate

    already_paid = ordered
      .select { |p| p != payment && p.date >= period_start && p.date <= period_end && chronologically_before?(p, payment, ordered) }
      .sum(&:interest_applied)

    [ period_interest - already_paid, 0 ].max
  end

  def chronologically_before?(a, b, ordered)
    ordered.index(a) < ordered.index(b)
  end

  def period_end_for(period_start)
    (period_start >> 1) - 1
  end
end
