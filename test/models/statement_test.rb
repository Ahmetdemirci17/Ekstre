require "test_helper"

class StatementTest < ActiveSupport::TestCase
  test "validates presence of source_filename" do
    statement = Statement.new
    assert_not statement.valid?
    assert_includes statement.errors[:source_filename], "can't be blank"
  end

  test "calculates spent and categorization metrics" do
    statement = statements(:august_statement)
    assert_equal 450.75, statement.total_spent
    assert_equal 1, statement.categorized_count
    assert_equal 0, statement.uncategorized_count
    assert_equal 100, statement.categorization_percentage
  end
end
