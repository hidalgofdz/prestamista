require "test_helper"

class AuthTest < ActionDispatch::IntegrationTest
  test "unauthenticated user is redirected to login page" do
    get loans_path

    assert_redirected_to new_session_path
  end

  test "lender signs up and is redirected to loans" do
    post registration_path, params: {
      registration: { name: "María", email: "maria@example.com" }
    }

    assert_redirected_to root_path
    follow_redirect!

    assert_response :success
    assert_equal 1, User.where(email: "maria@example.com").count
    assert_equal "María", User.find_by(email: "maria@example.com").account.name
  end

  test "lender requests magic link and email is sent" do
    post session_path, params: {
      session: { email: "hidalgo@example.com" }
    }

    assert_redirected_to new_session_path
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test "magic link request with unknown email shows same message" do
    post session_path, params: {
      session: { email: "unknown@example.com" }
    }

    assert_redirected_to new_session_path
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  test "lender clicks valid magic link and is logged in" do
    user = users(:hidalgo)
    token = user.generate_token_for(:magic_link)

    get verify_session_path(token: token)

    assert_redirected_to root_path
    follow_redirect!

    assert_response :success
  end

  test "lender clicks expired magic link and sees login page" do
    user = users(:hidalgo)
    token = user.generate_token_for(:magic_link)

    travel 16.minutes

    get verify_session_path(token: token)

    assert_redirected_to new_session_path
  end

  test "sign up with existing email redirects back" do
    post registration_path, params: {
      registration: { name: "Duplicate", email: "hidalgo@example.com" }
    }

    assert_redirected_to new_registration_path
  end

  test "lender logs out and is redirected to login" do
    sign_in users(:hidalgo)

    delete session_path

    assert_redirected_to new_session_path
    get loans_path
    assert_redirected_to new_session_path
  end

  test "sign_in authenticates as the given user" do
    sign_in users(:other_user)
    get loan_path(loans(:other_account_loan))
    assert_response :success
  end
end
