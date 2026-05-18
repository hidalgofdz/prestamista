require "test_helper"

class LoanTest < ActiveSupport::TestCase
  test "monthly payment for 50k loan at 18% APR over 24 months" do
    loan = Loan.new(
      amount: 50_000,
      annual_interest_rate: 18,
      term_months: 24,
      start_date: Date.current,
      account: accounts(:one),
      borrower: borrowers(:aaron)
    )

    assert_in_delta 2496.21, loan.monthly_payment, 0.01
  end

  test "monthly payment for interest-free loan is principal divided by term" do
    loan = Loan.new(
      amount: 50_000,
      annual_interest_rate: 0,
      term_months: 24,
      start_date: Date.current,
      account: accounts(:one),
      borrower: borrowers(:aaron)
    )

    assert_in_delta 2083.33, loan.monthly_payment, 0.01
  end

  test "next_payment_date is one month after start when no payments" do
    loan = loans(:active_loan)

    assert_equal Date.new(2026, 6, 1), loan.next_payment_date
  end

  test "next_payment_date advances after period is fully covered" do
    loan = loans(:active_loan)

    travel_to Date.new(2026, 6, 1) do
      loan.payments.create!(amount: 933.33, date: Date.new(2026, 6, 1), account: loan.account)
      assert_equal Date.new(2026, 7, 1), loan.next_payment_date
    end
  end

  test "overdue when next due date is in the past and period not covered" do
    loan = loans(:active_loan)

    travel_to Date.new(2026, 6, 2) do
      assert loan.overdue?
    end
  end

  test "partial payment does not clear overdue" do
    loan = loans(:active_loan)

    travel_to Date.new(2026, 6, 1) do
      loan.payments.create!(amount: 200, date: Date.new(2026, 6, 1), account: loan.account)
    end

    travel_to Date.new(2026, 6, 2) do
      assert loan.overdue?
    end
  end

  test "not overdue on the due date itself" do
    loan = loans(:active_loan)

    travel_to Date.new(2026, 6, 1) do
      assert_not loan.overdue?
    end
  end

  test "extra principal payment on same date does not advance next payment date" do
    loan = loans(:active_loan)

    travel_to Date.new(2026, 6, 1) do
      loan.payments.create!(amount: 933.33, date: Date.new(2026, 6, 1), account: loan.account)
      loan.payments.create!(amount: 2000, date: Date.new(2026, 6, 1), account: loan.account)

      assert_equal Date.new(2026, 7, 1), loan.next_payment_date
    end
  end

  test "extra principal payment in next period window does not cover that period" do
    loan = loans(:active_loan)

    travel_to Date.new(2026, 6, 15) do
      loan.payments.create!(amount: 933.33, date: Date.new(2026, 6, 1), account: loan.account)
      loan.payments.create!(amount: 2000, date: Date.new(2026, 6, 15), account: loan.account)

      assert_equal Date.new(2026, 7, 1), loan.next_payment_date
    end
  end

  test "account defaults to borrower's account" do
    loan = Loan.new(
      borrower: borrowers(:aaron),
      amount: 5000,
      annual_interest_rate: 10,
      term_months: 6,
      start_date: Date.current
    )
    loan.valid?

    assert_equal borrowers(:aaron).account, loan.account
  end

  test "updating a loan touches borrower's updated_at" do
    loan = loans(:active_loan)
    borrower = loan.borrower

    travel_to 1.day.from_now do
      loan.update!(amount: loan.amount + 1000)
      assert_equal Time.current, borrower.reload.updated_at
    end
  end

  test "paid-off loan is never overdue even if periods are uncovered" do
    loan = Loan.create!(
      account: accounts(:one),
      borrower: borrowers(:aaron),
      amount: 1000,
      annual_interest_rate: 0,
      term_months: 3,
      start_date: Date.new(2026, 1, 1)
    )

    travel_to Date.new(2026, 1, 15) do
      loan.payments.create!(amount: 1000, date: Date.new(2026, 1, 15), account: loan.account)
    end

    travel_to Date.new(2026, 4, 2) do
      assert loan.paid_off?
      assert_not loan.overdue?
    end
  end

  test "recalculate_payments recalculates downstream payment splits after editing first payment" do
    loan = loans(:active_loan)

    travel_to Date.new(2026, 7, 1) do
      payment1 = loan.payments.create!(amount: 933.33, date: Date.new(2026, 6, 1), account: loan.account)
      payment2 = loan.payments.create!(amount: 933.33, date: Date.new(2026, 7, 1), account: loan.account)

      payment1.update_columns(amount: 500)
      loan.recalculate_payments

      payment1.reload
      assert_in_delta 100.00, payment1.interest_applied.to_f, 0.01
      assert_in_delta 400.00, payment1.principal_applied.to_f, 0.01

      payment2.reload
      assert_in_delta 96.00, payment2.interest_applied.to_f, 0.01
      assert_in_delta 837.33, payment2.principal_applied.to_f, 0.01
    end
  end

  test "recalculate_payments raises when downstream payment exceeds balance" do
    loan = loans(:active_loan)

    travel_to Date.new(2026, 7, 1) do
      loan.payments.create!(amount: 100, date: Date.new(2026, 6, 1), account: loan.account)
      payment2 = loan.payments.create!(amount: 10_000, date: Date.new(2026, 7, 1), account: loan.account)

      original_interest = payment2.interest_applied
      original_principal = payment2.principal_applied

      loan.payments.order(:date).first.update_columns(amount: 5000)

      assert_raises ActiveRecord::RecordInvalid do
        loan.recalculate_payments
      end

      payment2.reload
      assert_equal original_interest, payment2.interest_applied
      assert_equal original_principal, payment2.principal_applied
    end
  end

  test "recalculate_payments handles date reorder correctly" do
    loan = loans(:active_loan)

    travel_to Date.new(2026, 8, 1) do
      payment1 = loan.payments.create!(amount: 500, date: Date.new(2026, 6, 15), account: loan.account)
      payment2 = loan.payments.create!(amount: 933.33, date: Date.new(2026, 7, 15), account: loan.account)

      payment1.update_columns(date: Date.new(2026, 8, 1))
      loan.recalculate_payments

      payment2.reload
      assert_in_delta 100.00, payment2.interest_applied.to_f, 0.01

      payment1.reload
      balance_after_p2 = loan.amount - payment2.principal_applied
      expected_interest = balance_after_p2 * loan.send(:monthly_rate)
      assert_in_delta expected_interest.to_f, payment1.interest_applied.to_f, 0.01
    end
  end
end
