require_relative 'scope_constants'

module ONCCertificationG10TestKit
  class SMARTInvalidTokenGroupSTU2 < Inferno::TestGroup
    include ScopeConstants

    title 'Invalid Access Token Request'
    short_title 'Invalid Token Request'
    input_instructions %(
      Register Inferno as a standalone application using the following information:

      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`
    )
    description %(
      This scenario verifies that a SMART Launch
      Sequence, specifically the [Standalone
      Launch](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
      Sequence, does not succeed in the case where the client sends an invalid
      Authorization code or client ID during the code exchange step. This must
      not result in a successful launch.

      This test is not included as part of earlier scenarios because some
      servers may not accept an authorization code after it has been used
      unsuccessfully in this manner.
    )
    id :g10_smart_invalid_token_request_stu2
    run_as_group

    config(
      inputs: {
        smart_auth_info: {
          name: :standalone_smart_auth_info,
          title: 'Standalone Launch Credentials',
          options: {
            mode: 'auth',
            components: [
              {
                name: :requested_scopes,
                default: STANDALONE_SMART_1_SCOPES
              },
              {
                name: :auth_type,
                default: 'symmetric',
                locked: true
              },
              {
                name: :auth_request_method,
                default: 'GET',
                locked: true
              },
              {
                name: :use_discovery,
                locked: true
              },
              {
                name: :pkce_support,
                default: 'enabled',
                locked: true
              },
              {
                name: :pkce_code_challenge_method,
                default: 'S256',
                locked: true
              }
            ]
          }
        },
        url: {
          title: 'Standalone FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by standalone applications'
        },
        code: {
          name: :invalid_token_code
        },
        state: {
          name: :invalid_token_state
        },
        pkce_code_verifier: {
          name: :invalid_token_pkce_code_verifier
        }
      },
      outputs: {
        code: { name: :invalid_token_code },
        state: { name: :invalid_token_state },
        expires_in: { name: :invalid_token_expires_in },
        pkce_code_verifier: { name: :invalid_token_pkce_code_verifier },
        smart_auth_info: { name: :standalone_smart_auth_info }
      },
      requests: {
        redirect: { name: :invalid_token_redirect },
        token: { name: :invalid_token_token }
      }
    )

    test from: :well_known_endpoint

    test from: :smart_app_redirect_stu2
    test from: :smart_code_received

    test do
      id 'Test03'
      title ' OAuth token exchange fails when supplied invalid code'
      description %(
        If the request failed verification or is invalid, the authorization
        server returns an error response.
      )
      uses_request :redirect

      input :smart_auth_info, type: :auth_info
      input :pkce_code_verifier,
            optional: true
      run do
        skip_if request.query_parameters['error'].present?, 'Error during authorization request'

        oauth2_params = {
          grant_type: 'authorization_code',
          code: 'BAD_CODE',
          redirect_uri: config.options[:redirect_uri]
        }
        oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

        if smart_auth_info.symmetric_auth?
          client_credentials = "#{smart_auth_info.client_id}:#{smart_auth_info.client_secret}"
          oauth2_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
        else
          oauth2_params[:client_id] = smart_auth_info.client_id
        end

        oauth2_params[:code_verifier] = pkce_code_verifier if smart_auth_info.pkce_enabled?

        post(smart_auth_info.token_url, body: oauth2_params, name: :token, headers: oauth2_headers)

        assert_response_status(400)
      end
    end

    test do
      id 'Test04'
      title 'OAuth token exchange fails when supplied invalid client ID'
      description %(
        If the request failed verification or is invalid, the authorization
        server returns an error response.
      )
      uses_request :redirect

      input :code
      input :smart_auth_info, type: :auth_info
      input :pkce_code_verifier,
            optional: true

      run do
        skip_if request.query_parameters['error'].present?, 'Error during authorization request'

        client_id = 'BAD_CLIENT_ID'

        oauth2_params = {
          grant_type: 'authorization_code',
          code:,
          redirect_uri: config.options[:redirect_uri]
        }
        oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

        if smart_auth_info.symmetric_auth?
          client_credentials = "#{client_id}:#{smart_auth_info.client_secret}"
          oauth2_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
        else
          oauth2_params[:client_id] = client_id
        end

        oauth2_params[:code_verifier] = pkce_code_verifier if smart_auth_info.pkce_enabled?

        post(smart_auth_info.token_url, body: oauth2_params, name: :token, headers: oauth2_headers)

        assert_response_status([400, 401])
      end
    end
  end
end
