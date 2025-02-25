module ONCCertificationG10TestKit
  class SMARTInvalidTokenRefreshTest < Inferno::Test
    id :g10_invalid_token_refresh
    title 'Refresh token exchange fails when supplied an invalid refresh token'
    description %(
      If the request failed verification or is invalid, the authorization server
      returns an error response.

      [OAuth 2.0 RFC (6749)](https://www.rfc-editor.org/rfc/rfc6749#section-6)
    )
    input :smart_auth_info, type: 'auth_info'
    input :received_scopes

    run do
      skip_if smart_auth_info.refresh_token.blank?,
              'No refresh token was received'

      oauth2_params = {
        'grant_type' => 'refresh_token',
        'refresh_token' => SecureRandom.uuid
      }
      oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

      oauth2_params['scope'] = received_scopes if config.options[:include_scopes]

      if smart_auth_info.symmetric_auth?
        credentials = Base64.strict_encode64("#{smart_auth_info.client_id}:#{smart_auth_info.client_secret}")
        oauth2_headers['Authorization'] = "Basic #{credentials}"
      else
        oauth2_params['client_id'] = smart_auth_info.client_id
      end

      post(smart_auth_info.token_url, body: oauth2_params, headers: oauth2_headers)

      assert_response_status([400, 401])
    end
  end
end
