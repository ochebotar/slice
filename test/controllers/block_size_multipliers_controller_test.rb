require 'test_helper'

class BlockSizeMultipliersControllerTest < ActionController::TestCase
  setup do
    login(users(:valid))
    @project = projects(:one)
    @randomization_scheme = randomization_schemes(:one)
    @block_size_multiplier = block_size_multipliers(:one)
  end

  test "should get index" do
    get :index, project_id: @project, randomization_scheme_id: @randomization_scheme
    assert_response :success
    assert_not_nil assigns(:block_size_multipliers)
  end

  test "should get new" do
    get :new, project_id: @project, randomization_scheme_id: @randomization_scheme
    assert_response :success
  end

  test "should create block_size_multiplier" do
    assert_difference('BlockSizeMultiplier.count') do
      post :create, project_id: @project, randomization_scheme_id: @randomization_scheme, block_size_multiplier: { value: 5, allocation: 1 }
    end

    assert_redirected_to project_randomization_scheme_block_size_multiplier_path(assigns(:project), assigns(:randomization_scheme), assigns(:block_size_multiplier))
  end

  test "should show block_size_multiplier" do
    get :show, project_id: @project, randomization_scheme_id: @randomization_scheme, id: @block_size_multiplier
    assert_response :success
  end

  test "should get edit" do
    get :edit, project_id: @project, randomization_scheme_id: @randomization_scheme, id: @block_size_multiplier
    assert_response :success
  end

  test "should update block_size_multiplier" do
    patch :update, project_id: @project, randomization_scheme_id: @randomization_scheme, id: @block_size_multiplier, block_size_multiplier: { value: @block_size_multiplier.value, allocation: 3 }
    assert_redirected_to project_randomization_scheme_block_size_multiplier_path(assigns(:project), assigns(:randomization_scheme), assigns(:block_size_multiplier))
  end

  test "should destroy block_size_multiplier" do
    assert_difference('BlockSizeMultiplier.current.count', -1) do
      delete :destroy, project_id: @project, randomization_scheme_id: @randomization_scheme, id: @block_size_multiplier
    end

    assert_redirected_to project_randomization_scheme_block_size_multipliers_path(assigns(:project), assigns(:randomization_scheme))
  end
end
