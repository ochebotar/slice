# frozen_string_literal: true

require "test_helper"

class AeModule::AdminsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:aes)
    @editor = users(:aes_editor)
  end

  test "should get dashboard" do
    login(@editor)
    get ae_module_admins_dashboard_url(@project)
    assert_response :success
  end
end
