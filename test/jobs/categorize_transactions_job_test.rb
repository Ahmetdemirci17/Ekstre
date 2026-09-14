require "test_helper"

class CategorizeTransactionsJobTest < ActiveJob::TestCase
  setup do
    @statement = statements(:september_statement)
    @tx = transactions(:uncategorized_electric)
  end

  test "categorizes uncategorized transactions in statement" do
    assert_nil @tx.category_id

    CategorizeTransactionsJob.perform_now(@statement.id)

    @tx.reload
    assert_not_nil @tx.category_id
    assert_equal "ai", @tx.categorized_by
    assert_equal "Fatura", @tx.category.name
    assert_not_nil @tx.merchant_name
    assert_not_nil @tx.ai_analysis
    assert_equal "categorized", @statement.reload.status
  end
end
