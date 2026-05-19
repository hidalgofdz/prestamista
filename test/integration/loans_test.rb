require "test_helper"

class LoansTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:hidalgo)
    @borrower = borrowers(:aaron)
  end

  test "lender sees all loans on the index" do
    get loans_path

    assert_response :success
    assert_select ".loan-card__borrower", /Aaron/
    assert_select ".loan-card__amount", /10,000/
  end

  test "lender views a loan with calculated summary" do
    loan = loans(:active_loan)

    get loan_path(loan)

    assert_response :success
    assert_select "h1", /Aaron/
    assert_select "dd p", /888/
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

  test "new loan form shows new borrower link" do
    get new_loan_path

    assert_response :success
    assert_select "a[href='#{new_loans_borrower_path}']", /prestatario/i
    assert_select "turbo-frame#inline_borrower_form"
  end

  test "edit loan form does not show new borrower link" do
    loan = loans(:active_loan)

    get edit_loan_path(loan)

    assert_response :success
    assert_select "a[href='#{new_loans_borrower_path}']", count: 0
    assert_select "turbo-frame#inline_borrower_form", count: 0
  end

  test "new loan form auto-loads inline borrower form when no borrowers exist" do
    sign_in_as users(:empty_lender)

    get new_loan_path

    assert_response :success
    assert_select "turbo-frame#inline_borrower_form[src=?]", new_loans_borrower_path
  end

  test "index shows active loans section with next payment date" do
    get loans_path

    assert_response :success
    assert_select ".filter-chip", /Activo/
    assert_select "[data-testid='next-payment']", /01\/06\/2026/
  end

  test "paid-off loans appear in separate section without next payment date" do
    get loans_path

    assert_response :success
    assert_select ".filter-chip", /Liquidado/
    assert_select ".filter-chip", /Activo/
  end

  test "active loans sorted newest first by start date" do
    Loan.create!(
      account: accounts(:one),
      borrower: @borrower,
      amount: 5000,
      annual_interest_rate: 10,
      term_months: 6,
      start_date: Date.new(2026, 5, 10)
    )

    get loans_path

    assert_response :success
    dates = css_select("[data-testid='next-payment']").map(&:text)
    assert_equal 2, dates.length
    assert_match(/10\/06\/2026/, dates.first)
    assert_match(/01\/06\/2026/, dates.last)
  end

  test "empty state when lender has no loans" do
    sign_in_as users(:empty_lender)

    get loans_path

    assert_response :success
    assert_select "p", /no tienes préstamos/i
    assert_select "a[href='#{new_loan_path}']"
  end

  test "overdue loan shows overdue badge with due date" do
    travel_to Date.new(2026, 6, 2) do
      get loans_path

      assert_response :success
      assert_select ".tag--danger", /Vencido/
      assert_select "[data-testid='next-payment']", /01\/06\/2026/
    end
  end

  test "new loan form prefills start date with today" do
    travel_to Date.new(2026, 5, 18) do
      get new_loan_path

      assert_response :success
      assert_select "input[name='loan[start_date]'][value='2026-05-18']"
    end
  end

  test "lender creates a loan and detail page shows all six fields" do
    travel_to Date.new(2026, 5, 18) do
      post loans_path, params: {
        loan: {
          borrower_id: @borrower.id,
          amount: "10000",
          annual_interest_rate: "12",
          term_months: "12",
          start_date: "2026-05-18"
        }
      }

      assert_response :redirect
      follow_redirect!

      assert_response :success
      assert_select "h1", /Aaron/
      assert_select "dd p", /10,000/
      assert_select "dd p", /12\.00/
      assert_select "dd p", "12"
      assert_select "dd p", /888/
      assert_select "dd p", /18\/05\/2026/
    end
  end

  test "lender creates a loan and index shows new loan alongside existing loans" do
    existing_loan = loans(:active_loan)

    post loans_path, params: {
      loan: {
        borrower_id: @borrower.id,
        amount: "3000",
        annual_interest_rate: "10",
        term_months: "6",
        start_date: "2026-05-18"
      }
    }

    assert_response :redirect

    get loans_path

    assert_response :success
    assert_select ".loan-card__amount", /3,000/
    assert_select ".loan-card__amount", /10,000/
    assert_select ".loan-card__borrower", text: /Aaron/, minimum: 2
  end

  test "two loans for same borrower are distinguishable by start date" do
    Loan.create!(
      account: accounts(:one),
      borrower: @borrower,
      amount: 10_000,
      annual_interest_rate: 12,
      term_months: 12,
      start_date: Date.new(2026, 3, 10)
    )

    get loans_path

    assert_response :success
    assert_select ".loan-card__borrower", text: /Aaron/, minimum: 2
    assert_select ".loan-card__subtitle", /10\/03\/2026/
    assert_select ".loan-card__subtitle", /01\/05\/2026/
  end
end
