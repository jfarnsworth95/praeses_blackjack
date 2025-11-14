require "test_helper"

class GameSessionsControllerTest < ActionController::TestCase
  test "should get start_game" do
    get :start_game
    assert_response :redirect
  end

  test "should get betting_phase" do
    session[:session_id] = "betting_phase_session"
    get :betting_phase
    assert_response :success
  end

  test "should get betting_phase redirect when player is out" do
    session[:session_id] = "player_out_session"
    get :betting_phase
    assert_response :redirect
  end

  test "should get redirect when phase doesn't match get action" do
    session[:session_id] = "play_phase_session"
    get :betting_phase
    assert_response :redirect
  end
end
