class Payment < ApplicationRecord
  belongs_to :account, default: -> { loan.account }
  belongs_to :loan

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

  before_validation :apply_to_interest_and_principal

  validate :amount_does_not_exceed_balance
  validate :date_not_in_future
  validate :proof_content_type_acceptable
  validate :proof_size_acceptable

  private
  def apply_to_interest_and_principal
    return unless loan && amount.present? && amount > 0 && date.present?

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
