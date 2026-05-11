ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  def sign_in(user)
    session = sessions(:hidalgo_session)
    cookies[:session_id] = session.id
  end

  def sign_in_as(user)
    session = user.sessions.create!(ip_address: "127.0.0.1", user_agent: "TestAgent")
    cookies[:session_id] = session.id
  end
end
