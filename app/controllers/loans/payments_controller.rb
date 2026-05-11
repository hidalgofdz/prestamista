class Loans::PaymentsController < ApplicationController
  include AccountScoped

  before_action :set_loan

  def create
    @payment = @loan.payments.new(payment_params)

    if @payment.save
      redirect_to loan_path(@loan)
    else
      redirect_to loan_path(@loan), alert: @payment.errors.full_messages.join(", ")
    end
  end

  private
  def set_loan
    @loan = @account.loans.find(params[:loan_id])
  end

  def payment_params
    params.require(:payment).permit(:amount, :date)
  end
end
