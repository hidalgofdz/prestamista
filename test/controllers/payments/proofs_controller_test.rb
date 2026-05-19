require "test_helper"

class Payments::ProofsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @image_payment = payments(:image_proof_payment)
    @pdf_payment = payments(:pdf_proof_payment)
    @no_proof_payment = payments(:no_proof_payment)
    @other_account_payment = payments(:other_account_payment)
    sign_in_as users(:proof_lender)
  end

  test "redirects to blob URL for image proof" do
    get payment_proof_path(@image_payment)
    assert_response :redirect
  end

  test "redirects to blob URL for PDF proof" do
    get payment_proof_path(@pdf_payment)
    assert_response :redirect
  end

  test "redirects to thumb variant URL for image with variant=thumb" do
    get payment_proof_path(@image_payment, variant: :thumb)
    assert_response :redirect
  end

  test "returns 404 when payment has no proof attached" do
    get payment_proof_path(@no_proof_payment)
    assert_response :not_found
  end

  test "returns 404 when payment belongs to another account" do
    get payment_proof_path(@other_account_payment)
    assert_response :not_found
  end

  test "deletes proof from payment" do
    @no_proof_payment.proof.attach(
      io: fixture_file_upload("sample.jpg", "image/jpeg"),
      filename: "sample.jpg",
      content_type: "image/jpeg"
    )
    assert @no_proof_payment.proof.attached?

    delete payment_proof_path(@no_proof_payment)

    assert_redirected_to loan_path(@no_proof_payment.loan)
    @no_proof_payment.reload
    assert_not @no_proof_payment.proof.attached?
  end

  test "deleting proof does not change payment amount or date" do
    @no_proof_payment.proof.attach(
      io: fixture_file_upload("sample.jpg", "image/jpeg"),
      filename: "sample.jpg",
      content_type: "image/jpeg"
    )
    original_amount = @no_proof_payment.amount
    original_date = @no_proof_payment.date

    delete payment_proof_path(@no_proof_payment)

    @no_proof_payment.reload
    assert_equal original_amount, @no_proof_payment.amount
    assert_equal original_date, @no_proof_payment.date
  end

  test "deleting proof returns 404 for other account" do
    delete payment_proof_path(@other_account_payment)
    assert_response :not_found
  end

  test "edit page shows current proof thumbnail and remove link" do
    get edit_loan_payment_path(loans(:proof_loan), @image_payment)
    assert_response :success
    assert_select ".payment-edit__current-proof"
    assert_select "a[data-turbo-method='delete'][href='#{payment_proof_path(@image_payment)}']"
  end

  test "redirects unauthenticated requests to sign in" do
    reset!
    get payment_proof_path(@image_payment)
    assert_redirected_to new_session_path
  end
end
