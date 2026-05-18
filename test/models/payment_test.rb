require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @loan = loans(:active_loan)
    travel_to Date.new(2026, 6, 1)
  end

  test "payment is valid without proof attached" do
    payment = @loan.payments.build(amount: 500, date: Date.current)
    assert payment.valid?
  end

  test "payment is valid with a JPEG image proof" do
    payment = @loan.payments.build(amount: 500, date: Date.current)
    payment.proof.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.jpg")),
      filename: "sample.jpg",
      content_type: "image/jpeg"
    )
    assert payment.valid?, payment.errors.full_messages.to_sentence
  end

  test "payment rejects an invalid content type" do
    payment = @loan.payments.build(amount: 500, date: Date.current)
    payment.proof.attach(
      io: StringIO.new("fake content"),
      filename: "virus.exe",
      content_type: "application/octet-stream"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:proof], I18n.t("activerecord.errors.models.payment.attributes.proof.invalid_content_type")
  end

  test "payment rejects files over 10 MB" do
    payment = @loan.payments.build(amount: 500, date: Date.current)
    payment.proof.attach(
      io: StringIO.new("x" * 100),
      filename: "big.jpg",
      content_type: "image/jpeg"
    )
    payment.proof.blob.byte_size = 11.megabytes
    assert_not payment.valid?
    assert_includes payment.errors[:proof], I18n.t("activerecord.errors.models.payment.attributes.proof.too_large")
  end
end
