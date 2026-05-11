module AccountScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_account
  end

  private
  def set_account
    @account = Current.account
  end
end
