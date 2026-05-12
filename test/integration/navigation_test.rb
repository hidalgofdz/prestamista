require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  test "authenticated lender sees navigation with app name, links, user name, and log out" do
    sign_in users(:hidalgo)

    get loans_path

    assert_response :success
    assert_select "nav.navbar" do
      assert_select "a.navbar-brand", "Prestamista"
      assert_select "a.navbar-link", /Préstamos/
      assert_select "a.navbar-link", /Prestatarios/
      assert_select "span.navbar-user", "Hidalgo"
      assert_select "button", /Cerrar sesión/
    end
  end

  test "unauthenticated visitor does not see the navigation" do
    get new_session_path

    assert_response :success
    assert_select "nav.navbar", count: 0
  end
end
