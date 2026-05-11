require "test_helper"

class LoansTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:hidalgo)
    @borrower = borrowers(:aaron)
  end

  test "lender sees all loans on the index" do
    get loans_path

    assert_response :success
    assert_select "a", /Aaron/
    assert_select "span", /10,000/
  end

  test "lender views a loan with calculated summary" do
    loan = loans(:active_loan)

    get loan_path(loan)

    assert_response :success
    assert_select "h1", /Aaron/
    assert_select "dd p", /833/
    assert_select "dd p", /100/
  end

  test "lender edits a loan" do
    loan = loans(:active_loan)

    patch loan_path(loan), params: {
      loan: { amount: "20000", term_months: "24" }
    }

    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_select "dd p", /20,000/
  end

  test "lender deletes a loan without payments" do
    loan = loans(:active_loan)

    assert_difference "Loan.count", -1 do
      delete loan_path(loan)
    end

    assert_redirected_to loans_path
  end

  test "lender cannot delete a loan with payments" do
    loan = loans(:active_loan)
    loan.payments.create!(amount: 100, date: "2026-05-10", account: loan.account)

    assert_no_difference "Loan.count" do
      delete loan_path(loan)
    end

    assert_redirected_to loans_path
  end

  test "lender creates a loan" do
    post loans_path, params: {
      loan: {
        borrower_id: @borrower.id,
        amount: "10000",
        annual_interest_rate: "12",
        term_months: "12"
      }
    }

    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_select "h1", /Aaron/
    assert_select "p", /10,000/
  end

  test "loan requires borrower and amount" do
    post loans_path, params: {
      loan: { borrower_id: "", amount: "" }
    }

    assert_response :unprocessable_entity
    assert_select "#errors li"
  end

  test "interest-free loan at 0% is valid" do
    post loans_path, params: {
      loan: {
        borrower_id: @borrower.id,
        amount: "5000",
        annual_interest_rate: "0",
        term_months: "6"
      }
    }

    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_select "dd p", /0/
  end

  test "lender cannot see another account's loan" do
    other_loan = loans(:other_account_loan)

    get loan_path(other_loan)

    assert_response :not_found
  end

  test "lender index only shows own loans" do
    get loans_path

    assert_response :success
    assert_select "a", text: /Aaron/
    assert_select "a", text: /Someone Else/, count: 0
  end
end
