class Loans::BorrowersController < ApplicationController
  include AccountScoped

  def new
    @borrower = @account.borrowers.new
  end

  def create
    @borrower = @account.borrowers.new(borrower_params)

    if @borrower.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to new_loan_path }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
  def borrower_params
    params.require(:borrower).permit(:name, :phone)
  end
end
