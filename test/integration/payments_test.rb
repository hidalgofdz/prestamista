require "test_helper"

class PaymentsTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Date.new(2026, 7, 15)
    sign_in users(:hidalgo)
    @loan = loans(:active_loan)
  end

  test "lender records a payment and sees updated balance" do
    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-06-01" }
    }

    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_select "dd p", /9,166.67/
    assert_select "#payments .payment-list__amount", /933.33/
  end

  test "partial payment applies interest first then principal" do
    post loan_payments_path(@loan), params: {
      payment: { amount: "250", date: "2026-06-01" }
    }

    follow_redirect!

    assert_select "dd p", /9,850.00/
    assert_select "#payments .payment-list__split", /Capital.*\$150\.00.*Interés.*\$100\.00/
  end

  test "payment less than interest due applies entirely to interest" do
    post loan_payments_path(@loan), params: {
      payment: { amount: "50", date: "2026-06-01" }
    }

    follow_redirect!

    assert_select "dd p", /10,000.00/

    payment = @loan.payments.last
    assert_equal BigDecimal("50"), payment.interest_applied
    assert_equal BigDecimal("0"), payment.principal_applied
  end

  test "extra payment after interest is covered goes entirely to principal" do
    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-06-01" }
    }

    post loan_payments_path(@loan), params: {
      payment: { amount: "2000", date: "2026-06-15" }
    }

    follow_redirect!

    assert_select "dd p", /7,166.67/

    extra_payment = @loan.payments.find_by(date: "2026-06-15")
    assert_equal BigDecimal("0"), extra_payment.interest_applied
    assert_equal BigDecimal("2000"), extra_payment.principal_applied
  end

  test "interest is calculated on reduced balance after extra principal payment" do
    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-06-01" }
    }
    post loan_payments_path(@loan), params: {
      payment: { amount: "2000", date: "2026-06-15" }
    }
    post loan_payments_path(@loan), params: {
      payment: { amount: "905.00", date: "2026-07-01" }
    }

    follow_redirect!

    assert_select "dd p", /6,333.34/

    month2_payment = @loan.payments.find_by(date: "2026-07-01")
    assert_in_delta 71.67, month2_payment.interest_applied.to_f, 0.01
    assert_in_delta 833.33, month2_payment.principal_applied.to_f, 0.01
  end

  test "payment requires a positive amount" do
    assert_no_difference "Payment.count" do
      post loan_payments_path(@loan), params: {
        payment: { amount: "", date: "2026-06-01" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "payment date cannot be in the future" do
    assert_no_difference "Payment.count" do
      post loan_payments_path(@loan), params: {
        payment: { amount: "933.33", date: "2026-07-16" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "payment cannot exceed remaining balance" do
    assert_no_difference "Payment.count" do
      post loan_payments_path(@loan), params: {
        payment: { amount: "15000", date: "2026-06-01" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "lender records a payment with proof attachment" do
    proof = fixture_file_upload("sample.jpg", "image/jpeg")

    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-06-01", proof: proof }
    }

    assert_response :redirect
    follow_redirect!

    assert_response :success
    payment = @loan.payments.last
    assert payment.proof.attached?
    assert_equal "image/jpeg", payment.proof.content_type
    assert_select ".payment-list__proof-thumb"
  end

  test "lender cannot record payment on another account's loan" do
    other_loan = loans(:other_account_loan)

    assert_no_difference "Payment.count" do
      post loan_payments_path(other_loan), params: {
        payment: { amount: "100", date: "2026-06-01" }
      }
    end

    assert_response :not_found
  end

  test "fully paid loan shows paid off indicator on detail page" do
    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-06-01" }
    }
    post loan_payments_path(@loan), params: {
      payment: { amount: "9166.67", date: "2026-06-15" }
    }

    get loan_path(@loan)

    assert_response :success
    assert_select ".paid-off"
  end

  test "fully paid loan shows in paid off section on index page" do
    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-06-01" }
    }
    post loan_payments_path(@loan), params: {
      payment: { amount: "9166.67", date: "2026-06-15" }
    }

    get loans_path

    assert_response :success
    assert_select "h2", text: /Activos/, count: 0
    assert_select "[data-testid='next-payment']", count: 0
  end

  test "payment history is in reverse chronological order" do
    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-06-01" }
    }
    post loan_payments_path(@loan), params: {
      payment: { amount: "905.00", date: "2026-07-01" }
    }

    get loan_path(@loan)

    assert_response :success
    dates = css_select("#payments .payment-list__date").map(&:text)
    assert_equal 2, dates.length
    assert dates.first.include?("julio") || dates.first.include?("07"), "Expected July first, got: #{dates.first}"
  end
end
