require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "validates presence of name" do
    cat = Category.new(color: "#123456")
    assert_not cat.valid?
    assert_includes cat.errors[:name], "can't be blank"
  end

  test "validates uniqueness of name case-insensitively" do
    duplicate = Category.new(name: "market", color: "#654321")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end
end
