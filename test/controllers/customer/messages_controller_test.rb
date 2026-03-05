require "test_helper"

class Customer::MessagesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get customer_messages_create_url
    assert_response :success
  end
end
