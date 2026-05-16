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

  test "extra principal payment does not advance next payment date beyond covered periods" do
    loan = loans(:active_loan)

    travel_to Date.new(2026, 6, 1) do
      loan.payments.create!(amount: 933.33, date: Date.new(2026, 6, 1), account: loan.account)
      loan.payments.create!(amount: 2000, date: Date.new(2026, 6, 1), account: loan.account)

      assert_equal Date.new(2026, 7, 1), loan.next_payment_date
    end
  end
end
