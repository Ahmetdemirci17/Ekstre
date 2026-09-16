require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  test "validates required fields" do
    tx = Transaction.new
    assert_not tx.valid?
    assert_includes tx.errors[:date], "can't be blank"
    assert_includes tx.errors[:description], "can't be blank"
    assert_includes tx.errors[:amount], "can't be blank"
    assert_includes tx.errors[:statement], "must exist"
  end

  test "detects expense and income correctly" do
    expense = transactions(:groceries)
    assert expense.expense?
    assert_not expense.income?
    assert_equal "450.75 TL", expense.formatted_amount
  end

  test "enum categorized_by defaults to unassigned" do
    tx = Transaction.new
    assert_equal "unassigned", tx.categorized_by
  end

  test "correctly handles unknown_merchant? and display_merchant formatting" do
    known_tx = Transaction.new(merchant_name: "Trendyol", description: "POS 123 IYZICO")
    assert_not known_tx.unknown_merchant?
    assert_equal "Trendyol", known_tx.display_merchant

    unknown_tx = Transaction.new(merchant_name: "Bilinmeyen Kurum", description: "Ref = 48291 HS")
    assert unknown_tx.unknown_merchant?
    assert_equal "Bilinmeyen Kurum (Ref = 48291 HS)", unknown_tx.display_merchant

    blank_tx = Transaction.new(merchant_name: nil, description: "Bilinmeyen Hareket")
    assert blank_tx.unknown_merchant?
    assert_equal "Bilinmeyen Kurum (Bilinmeyen Hareket)", blank_tx.display_merchant
  end
end
