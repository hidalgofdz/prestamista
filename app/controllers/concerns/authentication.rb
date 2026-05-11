module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  private
  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session = Session.find_by(id: cookies[:session_id])
  end

  def request_authentication
    redirect_to new_session_path
  end

  def start_session(user)
    session = user.sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    Current.session = session
    cookies.permanent[:session_id] = { value: session.id, httponly: true }
    session
  end

  def end_session
    Current.session&.destroy
    cookies.delete(:session_id)
  end

  def authenticated?
    Current.session.present?
  end
end
