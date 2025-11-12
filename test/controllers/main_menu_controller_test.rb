require "test_helper"

class MainMenuControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get main_menu_index_url
    assert_response :success
  end
end
