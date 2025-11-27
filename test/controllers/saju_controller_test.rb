require "test_helper"

class SajuControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get saju_index_url
    assert_response :success
  end

  test "should get result" do
    get saju_result_url
    assert_response :success
  end
end
