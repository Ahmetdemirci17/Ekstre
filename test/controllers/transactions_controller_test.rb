require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @transaction = transactions(:uncategorized_electric)
    @category = categories(:fatura)
  end

  test "should update category via turbo stream" do
    patch transaction_url(@transaction), 
          params: { transaction: { category_id: @category.id } },
          as: :turbo_stream

    assert_response :success
    assert_equal @category.id, @transaction.reload.category_id
    assert_equal "manual", @transaction.categorized_by
  end
end
