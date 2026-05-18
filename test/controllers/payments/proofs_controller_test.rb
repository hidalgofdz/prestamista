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

  test "redirects unauthenticated requests to sign in" do
    reset!
    get payment_proof_path(@image_payment)
    assert_redirected_to new_session_path
  end
end
