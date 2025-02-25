require_relative 'scope_constants'

module ONCCertificationG10TestKit
  class InvalidSMARTTokenRequestTest < Inferno::Test
    title 'OAuth token exchange fails when supplied invalid code_verifier'
    description %(
      If the request failed verification or is invalid, the authorization
      server returns an error response.
    )
    uses_request :redirect
    id :invalid_pkce_request

    input :code, :pkce_code_verifier
    input :smart_auth_info, type: :auth_info

    def modify_oauth_params(oauth_params)
      oauth_params
    end

    run do
      skip_if request.query_parameters['error'].present?, 'Error during authorization request'

      oauth2_params = {
        grant_type: 'authorization_code',
        code:,
        redirect_uri: config.options[:redirect_uri]
      }

      oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

      if smart_auth_info.symmetric_auth?
        client_credentials = "#{smart_auth_info.client_id}:#{smart_auth_info.client_secret}"
        oauth2_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
      else
        oauth2_params[:client_id] = smart_auth_info.client_id
      end

      modify_oauth_params(oauth2_params)

      post(smart_auth_info.token_url, body: oauth2_params, name: :token, headers: oauth2_headers)

      assert_response_status([400, 401])
    end
  end

  class SMARTInvalidPKCEGroup < Inferno::TestGroup
    include ScopeConstants

    title 'Invalid PKCE Code Verifier'
    short_title 'Invalid PKCE Code Verifier'
    input_instructions %(
      Register Inferno as a standalone application using the following information:

      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`
    )
    description %(
      This scenario verifies that a SMART Launch Sequence, specifically the
      [Standalone
      Launch](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
      Sequence, verifies that servers properly support PKCE.  It does this by
      ensuring the launch fails in the case where the client sends an invalid
      PKCE `code_verifier`.

      This group performs four launches with various forms of an invalid `code_verifier`
      (e.g. incorrect `code_verifier`, blank `code_identifier`) and verifies that these do
      not result in a successful launch.  Testers can expect to be prompted four times
      that a redirect will occur in this test.

      This test is not included as part of the Single Patient App group
      because there is no way for a client to infer that PKCE is supported on the server
      properly without performing extra launches.  Attempting to verify this within the
      same launch cannot be done because some servers may not accept an authorization code
      after it has been used unsuccessfully in this manner.
    )
    id :g10_smart_invalid_pkce_code_verifier_group
    run_as_group

    input :smart_auth_info, type: :auth_info

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
        pkce_code_challenge: {
          name: :invalid_token_pkce_code_challenge
        },
        pkce_code_verifier: {
          name: :invalid_token_pkce_code_verifier
        }
      },
      outputs: {
        code: { name: :invalid_token_code },
        state: { name: :invalid_token_state },
        pkce_code_challenge: { name: :invalid_token_pkce_code_challenge },
        pkce_code_verifier: { name: :invalid_token_pkce_code_verifier },
        smart_auth_info: { name: :standalone_smart_auth_info }
      },
      requests: {
        redirect: { name: :invalid_token_redirect },
        token: { name: :invalid_token_token }
      }
    )

    test from: :well_known_endpoint

    test from: :smart_app_redirect_stu2,
         id: :smart_no_code_verifier_redirect,
         config: {
           options: {
             redirect_message_proc: lambda do |auth_url|
               %(
                ### Invalid PKCE code_verifier 1/4

                This launch does not provide a `code_verifier` and verifies the
                server does not issue an access token.

                [Follow this link to authorize with the SMART
                server](#{auth_url}).

                  Tests will resume once Inferno receives a request at
                  `#{config.options[:redirect_uri]}` with a state of `#{state}`.
               )
             end
           }
         }
    test from: :smart_code_received,
         id: :smart_no_code_verifier_code_received
    test from: :invalid_pkce_request do
      title 'OAuth token exchange fails when no code_verifier is given'
      id :smart_no_verifier_token_request
    end

    test from: :smart_app_redirect_stu2,
         id: :smart_blank_code_verifier_redirect,
         config: {
           options: {
             redirect_message_proc: lambda do |auth_url|
               %(
                ### Invalid PKCE code_verifier 2/4

                This launch provides a blank `code_verifier` and verifies the
                server does not issue an access token.

                [Follow this link to authorize with the SMART
                server](#{auth_url}).

                  Tests will resume once Inferno receives a request at
                  `#{config.options[:redirect_uri]}` with a state of `#{state}`.
               )
             end
           }
         }
    test from: :smart_code_received,
         id: :smart_blank_code_verifier_code_received
    test from: :invalid_pkce_request do
      title 'OAuth token exchange fails when code_verifier is blank'
      id :smart_blank_verifier_token_request

      def modify_oauth_params(oauth_params)
        oauth_params.merge!(code_verifier: '')
      end
    end

    test from: :smart_app_redirect_stu2,
         id: :smart_bad_code_verifier_redirect,
         config: {
           options: {
             redirect_message_proc: lambda do |auth_url|
               %(
                ### Invalid PKCE code_verifier 3/4

                This launch provides an invalid `code_verifier` and verifies the
                server does not issue an access token.

                [Follow this link to authorize with the SMART
                server](#{auth_url}).

                  Tests will resume once Inferno receives a request at
                  `#{config.options[:redirect_uri]}` with a state of `#{state}`.
               )
             end
           }
         }
    test from: :smart_code_received,
         id: :smart_bad_code_verifier_code_received
    test from: :invalid_pkce_request do
      title 'OAuth token exchange fails when code_verifier is incorrect'
      id :smart_bad_code_verifier_token_request

      def modify_oauth_params(oauth_params)
        oauth_params.merge!(code_verifier: "#{SecureRandom.uuid}-#{SecureRandom.uuid}")
      end
    end

    test from: :smart_app_redirect_stu2,
         id: :smart_plain_code_verifier_redirect,
         config: {
           options: {
             redirect_message_proc: lambda do |auth_url|
               %(
                ### Invalid PKCE code_verifier 4/4

                This launch provides a `plain` `code_verifier` instead of one
                encoded with `S256` and verifies the server does not issue an
                access token.

                [Follow this link to authorize with the SMART
                server](#{auth_url}).

                  Tests will resume once Inferno receives a request at
                  `#{config.options[:redirect_uri]}` with a state of `#{state}`.
               )
             end
           }
         }
    test from: :smart_code_received,
         id: :smart_plain_code_verifier_code_received
    test from: :invalid_pkce_request do
      title 'OAuth token exchange fails when code_verifier matches code_challenge'
      id :smart_plain_code_verifier_token_request

      input :pkce_code_challenge

      def modify_oauth_params(oauth_params)
        oauth_params.merge!(code_verifier: pkce_code_challenge)
      end
    end
  end
end
