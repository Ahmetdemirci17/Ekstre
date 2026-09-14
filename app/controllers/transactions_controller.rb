class TransactionsController < ApplicationController
  def update
    @transaction = Transaction.find(params[:id])
    category_id = params.dig(:transaction, :category_id).presence

    if @transaction.update(category_id: category_id, categorized_by: :manual)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: statement_path(@transaction.statement), notice: "Kategori güncellendi." }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: statement_path(@transaction.statement), alert: "Kategori güncellenemedi." }
      end
    end
  end
end
