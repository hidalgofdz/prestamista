require "test_helper"

class BorrowersTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:hidalgo)
  end

  test "lender sees all borrowers" do
    get borrowers_path

    assert_response :success
    assert_select "a", borrowers(:aaron).name
  end

  test "lender views a borrower" do
    borrower = borrowers(:aaron)

    get borrower_path(borrower)

    assert_response :success
    assert_select "h1", borrower.name
    assert_select "p", borrower.phone
  end

  test "lender edits a borrower" do
    borrower = borrowers(:aaron)

    patch borrower_path(borrower), params: {
      borrower: { name: "Aaron Updated", phone: "5559999999" }
    }

    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_select "h1", "Aaron Updated"
    assert_select "p", /5559999999/
  end

  test "lender deletes a borrower without loans" do
    borrower = borrowers(:no_loans)

    assert_difference "Borrower.count", -1 do
      delete borrower_path(borrower)
    end

    assert_redirected_to borrowers_path
  end

  test "lender cannot delete a borrower with loans" do
    borrower = borrowers(:aaron)

    assert_no_difference "Borrower.count" do
      delete borrower_path(borrower)
    end

    assert_redirected_to borrowers_path
  end

  test "lender creates a borrower" do
    post borrowers_path, params: {
      borrower: { name: "Aaron", phone: "5551234567" }
    }

    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_select "h1", "Aaron"
    assert_select "p", /5551234567/
  end

  test "lender cannot see another account's borrowers" do
    other_borrower = borrowers(:other_borrower)

    get borrower_path(other_borrower)

    assert_response :not_found
  end

  test "lender index only shows own borrowers" do
    get borrowers_path

    assert_response :success
    assert_select "a", text: "Aaron"
    assert_select "a", text: "Someone Else", count: 0
  end

  test "empty state when lender has no borrowers" do
    sign_in_as users(:empty_lender)

    get borrowers_path

    assert_response :success
    assert_select ".table-state__title", /no hay prestatarios/i
    assert_select "a[href='#{new_borrower_path}']"
  end

  test "creating a borrower without name or phone shows validation errors" do
    post borrowers_path, params: {
      borrower: { name: "", phone: "" }
    }

    assert_response :unprocessable_entity
    assert_select "#errors li", count: 2
  end
end
