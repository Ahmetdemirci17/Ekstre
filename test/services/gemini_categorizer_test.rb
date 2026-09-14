require "test_helper"

class GeminiCategorizerTest < ActiveSupport::TestCase
  setup do
    @statement = statements(:september_statement)
    @tx = transactions(:uncategorized_electric)
  end

  test "uses fallback categorization when no API key configured" do
    categorizer = GeminiCategorizer.new([@tx])
    result = categorizer.call

    assert result[:success]
    assert result[:fallback]
    assert_equal "Fatura", result[:results][@tx.id]
  end

  test "fallback correctly identifies market and entertainment" do
    tx1 = Transaction.new(id: 101, description: "BIM BIRLESIK MAGAZALAR", amount: -85.50)
    tx2 = Transaction.new(id: 102, description: "NETFLIX ABONELIK", amount: -199.99)
    tx3 = Transaction.new(id: 103, description: "MAAS ODEMESI", amount: 25000.00)

    categorizer = GeminiCategorizer.new([tx1, tx2, tx3])
    result = categorizer.call

    assert result[:success]
    assert_equal "Market", result[:results][101]
    assert_equal "Eğlence", result[:results][102]
    assert_equal "Maaş / Gelir", result[:results][103]
  end
end
