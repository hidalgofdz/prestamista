class BorrowersController < ApplicationController
  include AccountScoped

  before_action :set_borrower, only: %i[show edit update destroy]

  def index
    @borrowers = @account.borrowers
  end

  def show
  end

  def new
    @borrower = @account.borrowers.new
  end

  def create
    @borrower = @account.borrowers.new(borrower_params)

    if @borrower.save
      redirect_to borrower_path(@borrower)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @borrower.update(borrower_params)
      redirect_to borrower_path(@borrower)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @borrower.destroy
    redirect_to borrowers_path
  end

  private
  def set_borrower
    @borrower = @account.borrowers.find(params[:id])
  end

  def borrower_params
    params.require(:borrower).permit(:name, :phone)
  end
end
