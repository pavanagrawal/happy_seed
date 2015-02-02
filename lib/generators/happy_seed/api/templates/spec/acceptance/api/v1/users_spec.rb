require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'User' do
  let(:user) { FactoryGirl.build :user_with_token }

  post '/v1/users', format: :json do
    parameter :first_name, 'First Name', scope: :user
    parameter :last_name, 'Last Name', scope: :user
    parameter :login, 'Login', required: true, scope: :user
    parameter :email, 'Email', required: true, scope: :user
    parameter :password, 'Password', required: true, scope: :user
    parameter :installation_identifier, 'Unique Installation Identifier', required: true, scope: :user_token
    parameter :avatar, 'Avatar', scope: :user

    let(:first_name) { user.first_name }
    let(:last_name) { user.last_name }
    let(:login) { user.login }
    let(:email) { user.email }
    let(:password) { user.password }
    let(:installation_identifier) { Faker::Lorem.characters 10 }
    # let(:avatar) { fixture_file_upload Rails.root.join('spec', 'resources', 'photo.jpg'), 'image/jpeg' }

    example_request 'sign up' do
      response_json = JSON.parse response_body

      expect(status).to eq(201)
      expect(response_json['user_token']).to have_key('token')
      expect(response_json['user_token']).to have_key('user')
    end
  end

  post '/v1/users/forgot_password', format: :json do
    before { user.save }

    parameter :email, 'Email', required: true, scope: :user
    let(:email) { user.email }

    example_request 'forgot password' do
      response_json = JSON.parse response_body

      expect(status).to eq(200)
      expect(response_json['user']['email']).to eq(email)
    end
  end

  put '/v1/users/reset_password', format: :json do
    before { user.save }

    parameter :reset_password_token, 'Reset password token', required: true, scope: :user
    parameter :password, 'Password', required: true, scope: :user
    parameter :password_confirmation, 'Password confirmation', required: true, scope: :user

    let(:reset_password_token) { user.reset_password_and_notify }
    let(:password) { Faker::Internet.password 8 }
    let(:password_confirmation) { password }

    example_request 'reset password' do
      response_json = JSON.parse response_body

      expect(status).to eq(200)
      expect(response_json['user']).to have_key('id')
    end
  end

  get '/v1/users/:id', format: :json do
    before { user.save }

    header 'AUTHORIZATION', :token

    parameter :id, 'User Unique Identifier', required: true

    let(:token) { ActionController::HttpAuthentication::Token.encode_credentials user.user_tokens.first.try(:token), installation_identifier: user.user_tokens.first.try(:installation_identifier) }
    let(:id) { user.id }

    example_request 'show' do
      response_json = JSON.parse response_body

      expect(status).to eq(200)
      expect(response_json['user']).to have_key('id')
    end
  end

  put '/v1/users/:id', format: :json do
    before { user.save }

    header 'AUTHORIZATION', :token

    parameter :id, 'User Unique Identifier', required: true
    parameter :full_name, 'Full Name', scope: :user
    parameter :username, 'User Name', scope: :user
    parameter :avatar, 'Avatar', scope: :user

    let(:token) { ActionController::HttpAuthentication::Token.encode_credentials user.user_tokens.first.try(:token), installation_identifier: user.user_tokens.first.try(:installation_identifier) }
    let(:id) { user.id }
    let(:first_name) { Faker::Name.first_name }
    let(:last_name) { Faker::Name.last_name }
    let(:login) { Faker::Internet.user_name }
    # let(:avatar) { fixture_file_upload Rails.root.join('spec', 'resources', 'photo.jpg'), 'image/jpeg' }

    example_request 'update' do
      explanation 'While this illustrates all possible parameters, any subset can be used. Example: to change only full_name, omit other optional parameters'
      response_json = JSON.parse response_body

      expect(status).to eq(200)
      expect(response_json['user']).to have_key('id')
    end
  end

  post '/v1/users/invite', format: :json do
    before { user.save }

    header 'AUTHORIZATION', :token

    parameter :invited, 'Invited Users', scope: :user

    let(:token) { ActionController::HttpAuthentication::Token.encode_credentials user.user_tokens.first.try(:token), installation_identifier: user.user_tokens.first.try(:installation_identifier) }
    let(:invited) { 2.times.map { |n| {email: Faker::Internet.free_email, full_name: Faker::Name.name} } }

    example_request 'invite' do
      response_json = JSON.parse response_body

      expect(status).to eq(200)
      expect(response_json['user']['invited']).not_to be_empty
    end

    example 'invite error', document: false do
      do_request user: {invited: 2.times.map { |n| {email: nil, full_name: Faker::Name.name} }}
      response_json = JSON.parse response_body

      expect(status).to eq(422)
      expect(response_json['errors']).to have_key('invited')
    end
  end
end