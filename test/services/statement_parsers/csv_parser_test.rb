require "test_helper"

class StatementParsers::CsvParserTest < ActiveSupport::TestCase
  test "parses semicolon delimited Turkish bank CSV with comma decimals" do
    csv_content = <<~CSV
      İşlem Tarihi;Açıklama;Tutar (TL)
      15.08.2026;MIGROS SUPERMARKET;-150,50
      16.08.2026;TURKCELL FATURA;-240,00
      18.08.2026;MAAS ODEMESI;35.000,00
    CSV

    parser = StatementParsers::CsvParser.new(csv_content)
    result = parser.call

    assert result[:success]
    assert_equal 3, result[:count]

    tx1 = result[:transactions][0]
    assert_equal Date.new(2026, 8, 15), tx1[:date]
    assert_equal "MIGROS SUPERMARKET", tx1[:description]
    assert_equal BigDecimal("-150.50"), tx1[:amount]

    tx3 = result[:transactions][2]
    assert_equal Date.new(2026, 8, 18), tx3[:date]
    assert_equal "MAAS ODEMESI", tx3[:description]
    assert_equal BigDecimal("35000.00"), tx3[:amount]
  end

  test "parses separate debit and credit columns" do
    csv_content = <<~CSV
      Tarih,Açıklama,Borç,Alacak
      2026-08-01,Kira Bedeli,15000.00,
      2026-08-05,Havale Gelen,,2500.00
    CSV

    parser = StatementParsers::CsvParser.new(csv_content)
    result = parser.call

    assert result[:success]
    assert_equal 2, result[:count]

    assert_equal BigDecimal("-15000.00"), result[:transactions][0][:amount]
    assert_equal BigDecimal("2500.00"), result[:transactions][1][:amount]
  end

  test "persists transactions to a statement when statement provided" do
    statement = statements(:september_statement)
    csv_content = <<~CSV
      Tarih;Açıklama;Tutar
      05.09.2026;NETFLIX.COM;-189,99
    CSV

    parser = StatementParsers::CsvParser.new(csv_content, statement: statement)
    assert_difference -> { statement.transactions.count }, 1 do
      result = parser.call
      assert result[:success]
    end

    assert_equal "parsed", statement.reload.status
  end

  test "returns error for empty content" do
    parser = StatementParsers::CsvParser.new("")
    result = parser.call
    assert_not result[:success]
    assert_equal "Dosya içeriği boş.", result[:error]
  end
end
