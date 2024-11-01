module ONCCertificationG10TestKit
  class SMARTAppLaunchInvalidAudGroup < Inferno::TestGroup
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
        client_id: {
          name: :standalone_client_id,
          title: 'Standalone Client ID',
          description: 'Client ID provided during registration of Inferno as a standalone application'
        },
        requested_scopes: {
          name: :standalone_requested_scopes,
          title: 'Standalone Scope',
          description: 'OAuth 2.0 scope provided by system to enable all required functionality',
          type: 'textarea',
          default: %(
            launch/patient openid fhirUser offline_access
            patient/Medication.read patient/AllergyIntolerance.read
            patient/CarePlan.read patient/CareTeam.read patient/Condition.read
            patient/Device.read patient/DiagnosticReport.read
            patient/DocumentReference.read patient/Encounter.read
            patient/Goal.read patient/Immunization.read patient/Location.read
            patient/MedicationRequest.read patient/Observation.read
            patient/Organization.read patient/Patient.read
            patient/Practitioner.read patient/Procedure.read
            patient/Provenance.read patient/PractitionerRole.read
          ).gsub(/\s{2,}/, ' ').strip
        },
        url: {
          title: 'Standalone FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by standalone applications'
        },
        smart_authorization_url: {
          title: 'OAuth 2.0 Authorize Endpoint',
          description: 'OAuth 2.0 Authorize Endpoint provided during the patient standalone launch'
        },
        smart_token_url: {
          title: 'OAuth 2.0 Token Endpoint',
          description: 'OAuth 2.0 Token Endpoint provided during the patient standalone launch'
        }
      },
      outputs: {
        state: { name: :invalid_aud_state }
      },
      requests: {
        redirect: { name: :invalid_aud_redirect }
      }
    )

    input_order :url,
                :standalone_client_id,
                :standalone_client_secret,
                :standalone_requested_scopes,
                :use_pkce,
                :pkce_code_challenge_method,
                :smart_authorization_url

    test from: :smart_app_redirect do
      required_suite_options G10Options::SMART_1_REQUIREMENT

      input :client_secret,
            name: :standalone_client_secret,
            title: 'Standalone Client Secret',
            description: 'Client Secret provided during registration of Inferno as a standalone application'

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
          use_pkce: {
            default: 'true',
            locked: true
          },
          pkce_code_challenge_method: {
            locked: true
          }
        }
      )

      input :client_secret,
            name: :standalone_client_secret,
            title: 'Standalone Client Secret',
            description: 'Client Secret provided during registration of Inferno as a standalone application'

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
          use_pkce: {
            default: 'true',
            locked: true
          },
          pkce_code_challenge_method: {
            locked: true
          }
        }
      )

      input :client_secret,
            name: :standalone_client_secret,
            title: 'Standalone Client Secret',
            description: 'Client Secret provided during registration of Inferno as a standalone application'

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
