class Admin::InvoicesController < AdminController
  load_and_authorize_resource

  def new
    @deposit = Deposit.new
  end

  def create
    r = Registrar.find_by(id: deposit_params[:registrar_id])
    @deposit = Deposit.new(deposit_params.merge(registrar: r))
    @invoice = @deposit.issue_prepayment_invoice

    if @invoice.persisted?
      flash[:notice] = t(:record_created)
      redirect_to [:admin, @invoice]
    else
      flash[:alert] = t(:failed_to_create_record)
      render 'new'
    end
  end

  def index
    @q = Invoice.includes(:account_activity).search(params[:q])
    @q.sorts  = 'id desc' if @q.sorts.empty?
    @invoices = @q.result.page(params[:page])
  end

  def show
    @invoice = Invoice.find(params[:id])
  end

  def cancel
    if @invoice.cancel
      flash[:notice] = t(:record_updated)
      redirect_to([:admin, @invoice])
    else
      flash.now[:alert] = t(:failed_to_update_record)
      render :show
    end
  end

  private

  def deposit_params
    params.require(:deposit).permit(:amount, :description, :registrar_id)
  end
end
