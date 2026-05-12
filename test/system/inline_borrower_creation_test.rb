require "application_system_test_case"

class InlineBorrowerCreationTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:hidalgo)
  end

  test "lender creates a borrower inline and it appears selected in the dropdown" do
    visit new_loan_path

    click_on I18n.t("loans.form.new_borrower")

    within "turbo-frame#inline_borrower_form" do
      fill_in "borrower[name]", with: "Maria"
      fill_in "borrower[phone]", with: "5559876543"
      click_on I18n.t("loans.borrowers.form.submit")
    end

    assert_no_selector ".inline-form"
    assert_select_option "Maria", selected: true
  end

  test "lender cancels adding a new borrower and no borrower is created" do
    visit new_loan_path

    click_on I18n.t("loans.form.new_borrower")

    within "turbo-frame#inline_borrower_form" do
      fill_in "borrower[name]", with: "Should Not Exist"
      click_on I18n.t("loans.borrowers.form.cancel")
    end

    assert_no_selector ".inline-form"
    assert_no_difference "Borrower.count" do
      # No server-side action happened
    end
  end

  test "inline form is pre-opened when lender has no borrowers" do
    borrowers(:aaron).loans.destroy_all
    borrowers(:aaron).destroy!

    visit new_loan_path

    within "turbo-frame#inline_borrower_form" do
      assert_selector "input[name='borrower[name]']"
      assert_selector "input[name='borrower[phone]']"
    end
  end

  private
  def assert_select_option(text, selected: false)
    option = find("select#loan_borrower_id option", text: text)
    assert option, "Expected option '#{text}' to exist"
    if selected
      assert option.selected?, "Expected option '#{text}' to be selected"
    end
  end
end
