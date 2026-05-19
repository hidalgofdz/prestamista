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

  test "payment with blank date returns validation error" do
    assert_no_difference "Payment.count" do
      post loan_payments_path(@loan), params: {
        payment: { amount: "933.33", date: "" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "#errors li", /Fecha/
  end

  test "payment cannot exceed remaining balance" do
    assert_no_difference "Payment.count" do
      post loan_payments_path(@loan), params: {
        payment: { amount: "15000", date: "2026-06-01" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "dd p", /10,000.00/
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

  # --- Edit Payment Tests ---

  test "lender edits a payment amount and sees updated split and balance" do
    sign_in users(:edit_lender)
    loan = loans(:edit_loan)
    payment = payments(:edit_payment)

    patch loan_payment_path(loan, payment), params: {
      payment: { amount: "1200", date: "2026-06-01" }
    }

    assert_redirected_to loan_path(loan)
    follow_redirect!

    assert_response :success
    assert_select "#payments .payment-list__split", /Capital.*\$1,100\.00.*Interés.*\$100\.00/
    assert_select "dd p", /8,900\.00/
  end

  test "edit rejects zero amount" do
    sign_in users(:edit_lender)

    patch loan_payment_path(loans(:edit_loan), payments(:edit_payment)), params: {
      payment: { amount: "0" }
    }

    assert_response :unprocessable_entity
  end

  test "edit rejects future date" do
    sign_in users(:edit_lender)

    patch loan_payment_path(loans(:edit_loan), payments(:edit_payment)), params: {
      payment: { date: "2026-07-16" }
    }

    assert_response :unprocessable_entity
  end

  test "edit rejects amount that would make downstream payment exceed balance" do
    post loan_payments_path(@loan), params: {
      payment: { amount: "100", date: "2026-06-01" }
    }
    post loan_payments_path(@loan), params: {
      payment: { amount: "10000", date: "2026-07-01" }
    }

    first_payment = @loan.payments.order(:date).first
    patch loan_payment_path(@loan, first_payment), params: {
      payment: { amount: "5000" }
    }

    assert_response :unprocessable_entity
    assert_select "#errors"
  end

  test "editing a payment on a paid-off loan can reactivate it" do
    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-06-01" }
    }
    post loan_payments_path(@loan), params: {
      payment: { amount: "9166.67", date: "2026-06-15" }
    }

    get loan_path(@loan)
    assert_select ".paid-off"

    last_payment = @loan.payments.order(date: :desc).first
    patch loan_payment_path(@loan, last_payment), params: {
      payment: { amount: "1000" }
    }

    assert_redirected_to loan_path(@loan)
    follow_redirect!
    assert_select ".paid-off", count: 0
  end

  test "editing a payment with new proof replaces old proof" do
    proof = fixture_file_upload("sample.jpg", "image/jpeg")
    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-06-01", proof: proof }
    }

    payment = @loan.payments.last
    assert payment.proof.attached?
    old_blob_id = payment.proof.blob.id

    new_proof = fixture_file_upload("sample.jpg", "image/jpeg")
    patch loan_payment_path(@loan, payment), params: {
      payment: { amount: "933.33", proof: new_proof }
    }

    assert_redirected_to loan_path(@loan)
    payment.reload
    assert payment.proof.attached?
    assert_not_equal old_blob_id, payment.proof.blob.id
  end

  test "editing without uploading proof preserves existing proof" do
    proof = fixture_file_upload("sample.jpg", "image/jpeg")
    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-06-01", proof: proof }
    }

    payment = @loan.payments.last
    old_blob_id = payment.proof.blob.id

    patch loan_payment_path(@loan, payment), params: {
      payment: { amount: "1000" }
    }

    assert_redirected_to loan_path(@loan)
    payment.reload
    assert payment.proof.attached?
    assert_equal old_blob_id, payment.proof.blob.id
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

  test "lender edits a payment date and interest split is recalculated" do
    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-06-01" }
    }

    payment = @loan.payments.last
    original_interest = payment.interest_applied

    patch loan_payment_path(@loan, payment), params: {
      payment: { date: "2026-06-15" }
    }

    assert_redirected_to loan_path(@loan)
    follow_redirect!

    assert_response :success
    payment.reload
    assert_equal original_interest, payment.interest_applied
    assert_select "#payments .payment-list__amount", /933.33/
  end

  test "editing a payment cascades recalculation to subsequent payments" do
    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-06-01" }
    }
    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-07-01" }
    }

    first_payment = @loan.payments.order(:date).first
    second_payment = @loan.payments.order(:date).last

    patch loan_payment_path(@loan, first_payment), params: {
      payment: { amount: "500" }
    }

    assert_redirected_to loan_path(@loan)
    follow_redirect!

    assert_response :success

    second_payment.reload
    assert_in_delta 96.00, second_payment.interest_applied.to_f, 0.01
    assert_in_delta 837.33, second_payment.principal_applied.to_f, 0.01

    assert_select "dd p", /8,762\.67/
  end

  test "editing a payment date reorders payments and recalculates splits" do
    post loan_payments_path(@loan), params: {
      payment: { amount: "500", date: "2026-06-15" }
    }
    post loan_payments_path(@loan), params: {
      payment: { amount: "933.33", date: "2026-07-01" }
    }

    first_payment = @loan.payments.find_by(date: "2026-06-15")
    second_payment = @loan.payments.find_by(date: "2026-07-01")

    patch loan_payment_path(@loan, first_payment), params: {
      payment: { date: "2026-07-15" }
    }

    assert_redirected_to loan_path(@loan)
    follow_redirect!

    assert_response :success

    second_payment.reload
    assert_in_delta 100.00, second_payment.interest_applied.to_f, 0.01

    first_payment.reload
    assert_equal Date.new(2026, 7, 15), first_payment.date
  end

  test "edit rejects amount that exceeds remaining balance" do
    sign_in users(:edit_lender)
    loan = loans(:edit_loan)
    payment = payments(:edit_payment)

    patch loan_payment_path(loan, payment), params: {
      payment: { amount: "15000" }
    }

    assert_response :unprocessable_entity
  end

  test "lender edits a payment to a lower amount and sees updated split and balance" do
    sign_in users(:edit_lender)
    loan = loans(:edit_loan)
    payment = payments(:edit_payment)

    patch loan_payment_path(loan, payment), params: {
      payment: { amount: "500", date: "2026-06-01" }
    }

    assert_redirected_to loan_path(loan)
    follow_redirect!

    assert_response :success
    assert_select "#payments .payment-list__split", /Capital.*\$400\.00.*Interés.*\$100\.00/
    assert_select "dd p", /9,600\.00/
  end

  test "lender cannot edit another account's payment" do
    other_loan = loans(:other_account_loan)
    other_payment = payments(:other_account_payment)

    patch loan_payment_path(other_loan, other_payment), params: {
      payment: { amount: "500" }
    }

    assert_response :not_found
  end
end
