class Current < ActiveSupport::CurrentAttributes
  attribute :session

  def user
    session&.user
  end

  def account
    user&.account
  end
end
