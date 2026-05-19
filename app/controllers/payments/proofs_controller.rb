class Payments::ProofsController < ApplicationController
  include AccountScoped
  include ActiveStorage::SetCurrent

  before_action :set_payment

  def show
    unless @payment.proof.attached?
      raise ActiveRecord::RecordNotFound
    end

    # allow_other_host: presigned S3 URLs live on a different domain (see ADR 0003)
    if params[:variant] == "thumb" && @payment.proof.variable?
      redirect_to @payment.proof.variant(:thumb).processed.url, allow_other_host: true
    elsif @payment.proof.content_type == "application/pdf"
      redirect_to @payment.proof.url(disposition: :attachment), allow_other_host: true
    else
      redirect_to @payment.proof.url(disposition: :inline), allow_other_host: true
    end
  end

  def destroy
    @payment.proof.purge
    redirect_to loan_path(@payment.loan)
  end

  private
  def set_payment
    @payment = @account.payments.find(params[:payment_id])
  end
end
