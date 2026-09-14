require "test_helper"

class StatementParsers::PdfParserTest < ActiveSupport::TestCase
  setup do
    @fixture_path = Rails.root.join("test/fixtures/files/sample_bank_statement.pdf")
  end

  test "successfully parses Turkish bank PDF statement with debit and credit indicators" do
    parser = StatementParsers::PdfParser.new(@fixture_path.to_s)
    result = parser.call

    assert result[:success], "Parser should succeed: #{result[:error]}"
    assert_equal 12, result[:count]

    salary = result[:transactions].find { |t| t[:description].include?("MAAS") }
    assert_not_nil salary
    assert_equal Date.new(2026, 9, 1), salary[:date]
    assert_equal BigDecimal("42500.00"), salary[:amount]

    market = result[:transactions].find { |t| t[:description].include?("MIGROS") }
    assert_not_nil market
    assert_equal Date.new(2026, 9, 2), market[:date]
    assert_equal BigDecimal("-854.20"), market[:amount]

    rent = result[:transactions].find { |t| t[:description].include?("KIRA") }
    assert_not_nil rent
    assert_equal BigDecimal("-18000.00"), rent[:amount]
  end

  test "automatically detects bank name and persists records to statement" do
    statement = Statement.create!(
      source_filename: "sample_bank_statement.pdf",
      imported_at: Time.current,
      status: :uploaded
    )

    parser = StatementParsers::PdfParser.new(@fixture_path.to_s, statement: statement)

    assert_difference -> { statement.transactions.count }, 12 do
      result = parser.call
      assert result[:success]
    end

    statement.reload
    assert_equal "Garanti BBVA", statement.bank_name
    assert_equal "parsed", statement.status
  end

  test "returns error when file does not exist or has invalid content" do
    parser = StatementParsers::PdfParser.new("/tmp/non_existent_file_12345.pdf")
    result = parser.call
    assert_not result[:success]
    assert_includes result[:error], "okunamadı"
  end
end
