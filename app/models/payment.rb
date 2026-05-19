class Payment < ApplicationRecord
  belongs_to :account, default: -> { loan.account }
  belongs_to :loan, touch: true

  attribute :date, :date, default: -> { Date.current }
  attribute :principal_applied, :decimal, default: 0
  attribute :interest_applied, :decimal, default: 0

  has_one_attached :proof do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 64, 64 ], preprocessed: true
  end

  PROOF_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/heic application/pdf].freeze
  PROOF_MAX_SIZE = 10.megabytes

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true

  before_validation :apply_to_interest_and_principal, on: :create

  validate :amount_does_not_exceed_balance, on: :create
  validate :date_not_in_future
  validate :proof_content_type_acceptable
  validate :proof_size_acceptable

  # Updates this payment's attrs and recalculates all payment splits on the loan
  # in chronological order. Returns false if this payment or any downstream payment
  # becomes invalid — the entire operation rolls back via the wrapping transaction.
  def update_and_recalculate(attrs)
    transaction do
      update!(attrs)
      loan.recalculate_payments
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, :downstream_payment_invalid) unless e.record == self
    false
  rescue Loan::PaymentExceedsBalance
    errors.add(:base, :downstream_payment_invalid)
    false
  end

  private
  def apply_to_interest_and_principal
    return unless loan && amount.present? && amount > 0 && date.present?

    interest_due = loan.interest_due_on(date, excluding: self)
    self.interest_applied = [ amount, interest_due ].min
    self.principal_applied = amount - interest_applied
  end

  def amount_does_not_exceed_balance
    return unless loan && principal_applied.present?

    if principal_applied > loan.remaining_balance(excluding: self)
      errors.add(:amount, :exceeds_balance)
    end
  end

  def date_not_in_future
    return unless date.present?

    if date > Date.current
      errors.add(:date, :in_future)
    end
  end

  def proof_content_type_acceptable
    return unless proof.attached?

    if PROOF_CONTENT_TYPES.exclude?(proof.content_type)
      errors.add(:proof, :invalid_content_type)
    end
  end

  def proof_size_acceptable
    return unless proof.attached?

    if proof.byte_size > PROOF_MAX_SIZE
      errors.add(:proof, :too_large)
    end
  end
end
