class AuthMailer < ApplicationMailer
  def magic_link(user)
    @user = user
    @url = verify_session_url(token: user.generate_token_for(:magic_link))
    mail to: user.email, subject: t(".subject")
  end
end
