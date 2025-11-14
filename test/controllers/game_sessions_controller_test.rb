require "test_helper"

class GameSessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get start_game" do
    get "/game"
    assert_response :redirect
  end
end
