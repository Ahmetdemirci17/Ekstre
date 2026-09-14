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
end
