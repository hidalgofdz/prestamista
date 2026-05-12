require "test_helper"

class Loans::BorrowersTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:hidalgo)
  end

  test "lender creates a borrower inline and dropdown is updated with new borrower selected" do
    assert_difference "Borrower.count", 1 do
      post loans_borrowers_path, params: {
        borrower: { name: "Maria", phone: "5559876543" }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_includes response.body, "borrower_select_wrapper"
    assert_includes response.body, "Maria"
    assert_includes response.body, "selected"
    assert_includes response.body, "inline_borrower_form"
  end

  test "invalid borrower re-renders inline form with errors" do
    assert_no_difference "Borrower.count" do
      post loans_borrowers_path, params: {
        borrower: { name: "", phone: "" }
      }, as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_select "#errors li"
  end

  test "borrower is scoped to the lender's account" do
    post loans_borrowers_path, params: {
      borrower: { name: "Maria", phone: "5559876543" }
    }, as: :turbo_stream

    borrower = Borrower.last
    assert_equal accounts(:one), borrower.account
  end

  test "html fallback redirects to new loan path" do
    post loans_borrowers_path, params: {
      borrower: { name: "Maria", phone: "5559876543" }
    }

    assert_redirected_to new_loan_path
  end
end
