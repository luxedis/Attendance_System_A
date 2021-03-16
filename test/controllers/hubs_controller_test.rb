require 'test_helper'

class HubsControllerTest < ActionDispatch::IntegrationTest
<<<<<<< HEAD
  # test "the truth" do
  #   assert true
  # end
=======
  test "should get index" do
    get hubs_index_url
    assert_response :success
  end

  test "should get show" do
    get hubs_show_url
    assert_response :success
  end

>>>>>>> 拠点一覧
end
