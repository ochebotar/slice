# frozen_string_literal: true

require 'test_helper'

# Tests to make sure users can be successfully invited to projects
class ProjectUsersControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
    @project_editor = users(:project_one_editor)
    @pending_editor_invite = project_users(:pending_editor_invite)
    @accepted_viewer_invite = project_users(:accepted_viewer_invite)
    @unblinded_member = project_users(:project_one_editor)
    @blinded_member = project_users(:project_one_editor_blinded)
  end

  test 'should resend project invitation' do
    login(users(:valid))
    post :resend, params: { id: @pending_editor_invite }, format: 'js'
    assert_not_nil assigns(:project_user)
    assert_not_nil assigns(:project)
    assert_template 'update'
    assert_response :success
  end

  test 'should not resend project invitation with invalid id' do
    login(users(:valid))
    post :resend, params: { id: -1 }, format: 'js'
    assert_nil assigns(:project_user)
    assert_nil assigns(:project)
    assert_template nil
    assert_response :success
  end

  test 'should get invite for logged in user' do
    login(users(:two))
    get :invite, params: { invite_token: @pending_editor_invite.invite_token }
    assert_equal session[:invite_token], @pending_editor_invite.invite_token
    assert_redirected_to accept_project_users_path
  end

  test 'should get invite for public user' do
    get :invite, params: { invite_token: @pending_editor_invite.invite_token }
    assert_equal session[:invite_token], @pending_editor_invite.invite_token
    assert_redirected_to new_user_session_path
  end

  test 'should accept project user' do
    login(users(:two))
    session[:invite_token] = @pending_editor_invite.invite_token
    get :accept

    assert_not_nil assigns(:project_user)
    assert_equal users(:two), assigns(:project_user).user
    assert_equal(
      'You have been successfully been added to the project.',
      flash[:notice]
    )
    assert_redirected_to assigns(:project_user).project
  end

  test 'should accept existing project user' do
    login(users(:valid))
    session[:invite_token] = project_users(:accepted_viewer_invite).invite_token
    get :accept

    assert_not_nil assigns(:project_user)
    assert_equal users(:valid), assigns(:project_user).user
    assert_equal(
      "You have already been added to #{assigns(:project_user).project.name}.",
      flash[:notice]
    )
    assert_redirected_to assigns(:project_user).project
  end

  test 'should not accept invalid token for project user' do
    login(users(:valid))
    get :accept, params: { invite_token: 'imaninvalidtoken' }

    assert_nil assigns(:project_user)
    assert_equal 'Invalid invitation token.', flash[:alert]
    assert_redirected_to root_path
  end

  test 'should not accept project user if invite token is already claimed' do
    login(users(:two))
    session[:invite_token] = 'accepted_viewer_invite'
    get :accept

    assert_not_nil assigns(:project_user)
    assert_not_equal users(:two), assigns(:project_user).user
    assert_equal 'This invite has already been claimed.', flash[:alert]
    assert_redirected_to root_path
  end

  test 'should set project user as blinded' do
    login(@project_editor)
    assert_difference('ProjectUser.where(unblinded: true).count', -1) do
      patch :update, params: {
        project_id: @project.id, id: @unblinded_member, unblinded: '0'
      }, format: 'js'
    end
    assert_template 'update'
    assert_response :success
  end

  test 'should set project user as unblinded' do
    login(@project_editor)
    assert_difference('ProjectUser.where(unblinded: false).count', -1) do
      patch :update, params: {
        project_id: @project.id, id: @blinded_member, unblinded: '1'
      }, format: 'js'
    end
    assert_template 'update'
    assert_response :success
  end

  test 'should destroy project user' do
    login(users(:valid))
    assert_difference('ProjectUser.count', -1) do
      delete :destroy, params: { id: @accepted_viewer_invite }, format: 'js'
    end
    assert_not_nil assigns(:project)
    assert_template 'projects/members'
  end

  test 'should allow viewer to remove self from project' do
    login(users(:project_one_viewer))
    assert_difference('ProjectUser.count', -1) do
      delete :destroy, params: {
        id: project_users(:project_one_viewer)
      }, format: 'js'
    end

    assert_not_nil assigns(:project)
    assert_template 'projects/members'
  end

  test 'should not destroy project user with invalid id' do
    login(users(:valid))
    assert_difference('ProjectUser.count', 0) do
      delete :destroy, params: { id: -1 }, format: 'js'
    end

    assert_nil assigns(:project)
    assert_response :success
  end
end
