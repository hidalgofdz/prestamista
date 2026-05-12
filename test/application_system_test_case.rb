require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]

  def sign_in_as(user)
    session = user.sessions.create!(ip_address: "127.0.0.1", user_agent: "SystemTest")
    visit new_session_path
    page.driver.browser.manage.add_cookie(name: "session_id", value: session.id)
  end
end
