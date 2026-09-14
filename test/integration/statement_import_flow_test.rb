require "test_helper"

class StatementImportFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "full statement upload, parsing, and categorization flow" do
    uploaded_file = fixture_file_upload("sample_bank_statement.csv", "text/csv")

    assert_difference -> { Statement.count }, 1 do
      assert_enqueued_with(job: CategorizeTransactionsJob) do
        post statements_url, params: {
          statement: {
            bank_name: "Garanti BBVA",
            file: uploaded_file
          }
        }
      end
    end

    statement = Statement.order(:created_at).last
    assert_redirected_to statement_path(statement)
    follow_redirect!
    assert_response :success

    # Verify transactions were parsed and created
    assert_equal 12, statement.transactions.count

    # Execute the enqueued job
    perform_enqueued_jobs

    statement.reload
    assert_equal "categorized", statement.status
    assert_equal 0, statement.uncategorized_count

    # Verify specific categories matched by fallback rules
    salary = statement.transactions.find_by("description LIKE ?", "%MAAŞ%")
    assert_equal "Maaş / Gelir", salary.category.name

    market = statement.transactions.find_by("description LIKE ?", "%MİGROS%")
    assert_equal "Market", market.category.name

    gas = statement.transactions.find_by("description LIKE ?", "%İGDAŞ%")
    assert_equal "Fatura", gas.category.name

    rent = statement.transactions.find_by("description LIKE ?", "%KİRA%")
    assert_equal "Kira & Konut", rent.category.name
  end
end
