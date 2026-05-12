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
end
