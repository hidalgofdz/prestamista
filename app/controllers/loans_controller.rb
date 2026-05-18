class LoansController < ApplicationController
  include AccountScoped

  before_action :set_loan, only: %i[show edit update destroy]

  def index
    loans = @account.loans.includes(:borrower, :payments).order(start_date: :desc)
    @active_loans = loans.reject(&:paid_off?)
    @paid_off_loans = loans.select(&:paid_off?)
  end

  def show
    @payment = @loan.payments.new
    @payments = @loan.payments.with_attached_proof.order(date: :desc, created_at: :desc)
  end

  def new
    @loan = @account.loans.new(start_date: Date.current)
  end

  def create
    @loan = @account.loans.new(loan_params)

    if @loan.save
      redirect_to loan_path(@loan)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @loan.update(loan_params)
      redirect_to loan_path(@loan)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @loan.destroy
      redirect_to loans_path
    else
      redirect_to loans_path, alert: @loan.errors.full_messages.join(", ")
    end
  end

  private
  def set_loan
    @loan = @account.loans.find(params[:id])
  end

  def loan_params
    params.require(:loan).permit(:borrower_id, :amount, :annual_interest_rate, :term_months, :start_date)
  end
end
