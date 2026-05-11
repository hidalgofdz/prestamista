class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: %i[new create verify]

  def new
  end

  def create
    user = User.find_by(email: params.dig(:session, :email))
    AuthMailer.magic_link(user).deliver_now if user
    redirect_to new_session_path, notice: t(".notice")
  end

  def verify
    user = User.find_by_token_for(:magic_link, params[:token])

    if user
      start_session(user)
      redirect_to root_path
    else
      redirect_to new_session_path
    end
  end

  def destroy
    end_session
    redirect_to new_session_path
  end
end
