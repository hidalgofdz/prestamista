class RegistrationsController < ApplicationController
  skip_before_action :require_authentication

  def new
  end

  def create
    user = User.register(
      name: params.dig(:registration, :name),
      email: params.dig(:registration, :email)
    )
    start_session(user)
    redirect_to root_path
  rescue ActiveRecord::RecordInvalid
    redirect_to new_registration_path, alert: t(".alert")
  end
end
