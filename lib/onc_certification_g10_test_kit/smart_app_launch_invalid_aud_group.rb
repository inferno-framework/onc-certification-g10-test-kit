require_relative 'scope_constants'

module ONCCertificationG10TestKit
  class SMARTAppLaunchInvalidAudGroup < Inferno::TestGroup
    include ScopeConstants

    title 'Invalid AUD Parameter'
    short_title 'Invalid AUD Launch'
    input_instructions %(
      Register Inferno as a standalone application using the following information:

      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`
    )
    description %(
      This scenario verifies that a SMART Launch Sequence, specifically the
      Standalone Launch Sequence, does not succeed in the case where the client
      sends an invalid FHIR server as the `aud` parameter during launch. This
      must fail to ensure that a genuine bearer token is not leaked to a
      counterfit resource server.

      This test is not included in earlier scenarios because it requires the
      browser of the user to be redirected to the authorization service, and
      there is no expectation that the authorization service redirects the user
      back to Inferno with an error message. The only requirement is that
      Inferno is not granted a code to exchange for a valid access token. Since
      this is a special case, it is tested independently in a separate sequence.

      Note that this test will launch a new browser window. The user is required
      to 'Attest' in the Inferno user interface after the launch does not
      succeed, if the server does not return an error code.

      The following implementation specifications are relevant to this scenario:

      * [Standalone Launch Sequence
        (STU1)](http://hl7.org/fhir/smart-app-launch/1.0.0/index.html#standalone-launch-sequence)
      * [Standalone Launch
        (STU2)](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
    )
    id :g10_smart_invalid_aud
    run_as_group

    config(
      inputs: {
        smart_auth_info: {
          name: :standalone_smart_auth_info,
          title: 'Standalone Launch Credentials',
          options: {
            mode: 'auth'
          }
        },
        url: {
          title: 'Standalone FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by standalone applications'
        }
      },
      outputs: {
        state: { name: :invalid_aud_state }
      },
      requests: {
        redirect: { name: :invalid_aud_redirect }
      }
    )

    test from: :smart_app_redirect do
      required_suite_options G10Options::SMART_1_REQUIREMENT

      config(
        inputs: {
          smart_auth_info: {
            name: :standalone_smart_auth_info,
            options: {
              components: [
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
                  name: :requested_scopes,
                  default: STANDALONE_SMART_1_SCOPES
                }
              ]
            }
          }
        }
      )

      def aud
        'https://inferno.healthit.gov/invalid_aud'
      end

      def wait_message(auth_url)
        %(
          Inferno will redirect you to an external website for authorization.
          **It is expected this will fail**. If the server does not return to
          Inferno automatically, but does provide an error message, you may
          return to Inferno and confirm that an error was presented in this
          window.

          * [Perform Invalid Launch](#{auth_url})
          * [Attest launch
            failed](#{Inferno::Application['base_url']}/custom/smart/redirect?state=#{state}&confirm_fail=true)
        )
      end
    end

    test from: :smart_app_redirect_stu2 do
      id :smart_app_redirect_stu2
      required_suite_options(G10Options::SMART_2_REQUIREMENT)

      config(
        inputs: {
          smart_auth_info: {
            name: :standalone_smart_auth_info,
            options: {
              components: [
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
                  name: :requested_scopes,
                  default: STANDALONE_SMART_2_SCOPES
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
          }
        }
      )

      def aud
        'https://inferno.healthit.gov/invalid_aud'
      end

      def wait_message(auth_url)
        %(
          Inferno will redirect you to an external website for authorization.
          **It is expected this will fail**. If the server does not return to
          Inferno automatically, but does provide an error message, you may
          return to Inferno and confirm that an error was presented in this
          window.

          * [Perform Invalid Launch](#{auth_url})
          * [Attest launch
            failed](#{Inferno::Application['base_url']}/custom/smart/redirect?state=#{state}&confirm_fail=true)
        )
      end
    end
    test from: :smart_app_redirect_stu2 do
      required_suite_options(G10Options::SMART_2_2_REQUIREMENT)
      id :smart_app_redirect_stu2_2 # rubocop:disable Naming/VariableNumber

      config(
        inputs: {
          smart_auth_info: {
            name: :standalone_smart_auth_info,
            options: {
              components: [
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
                  name: :requested_scopes,
                  default: STANDALONE_SMART_2_SCOPES
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
          }
        }
      )

      def aud
        'https://inferno.healthit.gov/invalid_aud'
      end

      def wait_message(auth_url)
        %(
          Inferno will redirect you to an external website for authorization.
          **It is expected this will fail**. If the server does not return to
          Inferno automatically, but does provide an error message, you may
          return to Inferno and confirm that an error was presented in this
          window.

          * [Perform Invalid Launch](#{auth_url})
          * [Attest launch
            failed](#{Inferno::Application['base_url']}/custom/smart/redirect?state=#{state}&confirm_fail=true)
        )
      end
    end

    test do
      title 'Inferno client app does not receive code parameter redirect URI'
      description %(
        Inferno redirected the user to the authorization service with an invalid AUD.
        Inferno expects that the authorization request will not succeed.  This can
        either be from the server explicitely pass an error, or stopping and the
        tester returns to Inferno to confirm that the server presented them a failure.
      )
      uses_request :redirect

      run do
        params = request.query_parameters

        assert params['code'].blank?,
               'Authorization has incorrectly succeeded because access code provided to Inferno.'

        pass_message =
          if params['error'].present?
            'Server redirected the user back to the app with an error.'
          elsif params['confirm_fail']
            'Tester attested that the authorization service did not succeed due to invalid AUD parameter.'
          else
            'Server redirected the user back to the app without an access code.'
          end

        pass pass_message
      end
    end
  end
end
