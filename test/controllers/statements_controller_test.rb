require "test_helper"

class StatementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @statement = statements(:august_statement)
  end

  test "should get index" do
    get statements_url
    assert_response :success
  end

  test "should get new" do
    get new_statement_url
    assert_response :success
  end

  test "should show statement" do
    get statement_url(@statement)
    assert_response :success
  end

  test "should destroy statement" do
    assert_difference("Statement.count", -1) do
      delete statement_url(@statement)
    end
    assert_redirected_to statements_url
  end
end
