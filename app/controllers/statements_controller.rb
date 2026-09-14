class StatementsController < ApplicationController
  before_action :set_statement, only: [:show, :destroy, :categorize]

  def index
    @statements = Statement.order(imported_at: :desc)
  end

  def show
    @transactions = @statement.transactions.chronological
    @categories = Category.order(:name)
  end

  def new
    @statement = Statement.new
  end

  def create
    uploaded_file = params.dig(:statement, :file)
    bank_name = params.dig(:statement, :bank_name).presence

    if uploaded_file.blank?
      @statement = Statement.new(bank_name: bank_name)
      flash.now[:alert] = "Lütfen yüklenecek bir CSV dosyası seçin."
      return render :new, status: :unprocessable_entity
    end

    @statement = Statement.new(
      source_filename: uploaded_file.original_filename,
      bank_name: bank_name,
      imported_at: Time.current,
      status: :uploaded
    )

    if @statement.save
      parser = StatementParsers::CsvParser.new(uploaded_file, statement: @statement)
      result = parser.call

      if result[:success]
        CategorizeTransactionsJob.perform_later(@statement.id)
        redirect_to statement_path(@statement), notice: "Ekstre başarıyla yüklendi! #{result[:count]} işlem aktarıldı. Yapay zeka kategorizasyonu arka planda çalışıyor."
      else
        @statement.destroy
        @statement = Statement.new(bank_name: bank_name)
        flash.now[:alert] = result[:error]
        render :new, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = @statement.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @statement.destroy
    redirect_to statements_path, notice: "Ekstre ve bağlı işlemler başarıyla silindi."
  end

  def categorize
    CategorizeTransactionsJob.perform_later(@statement.id)
    redirect_to statement_path(@statement), notice: "Yapay zeka kategorizasyonu başlatıldı."
  end

  private

  def set_statement
    @statement = Statement.find(params[:id])
  end
end
