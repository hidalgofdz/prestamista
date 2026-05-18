class Loans::PaymentsController < ApplicationController
  include AccountScoped

  before_action :set_loan
  before_action :set_payment, only: %i[edit update]

  def create
    @payment = @loan.payments.new(payment_params)

    if @payment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to loan_path(@loan) }
      end
    else
      @payments = @loan.payments.with_attached_proof.order(date: :desc, created_at: :desc)
      render "loans/show", status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @payment.update_and_recalculate(payment_params)
      redirect_to loan_path(@loan)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
  def set_loan
    @loan = @account.loans.find(params[:loan_id])
  end

  def set_payment
    @payment = @loan.payments.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:amount, :date, :proof)
  end
end
