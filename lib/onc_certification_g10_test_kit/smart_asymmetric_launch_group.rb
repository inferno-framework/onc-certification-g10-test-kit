require_relative 'base_token_refresh_stu2_group'
require_relative 'patient_context_test'
require_relative 'scope_constants'

module ONCCertificationG10TestKit
  class SMARTAsymmetricLaunchGroup < Inferno::TestGroup
    include ScopeConstants

    title 'Asymmetric Client Standalone Launch'
    short_title 'Asymmetric Client Launch'
    description %(
      The [Standalone
      Launch Sequence](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
      allows an app, like Inferno, to be launched independent of an
      existing EHR session. It is one of the two launch methods described in
      the SMART App Launch Framework alongside EHR Launch. The app will
      request authorization for the provided scope from the authorization
      endpoint, ultimately receiving an authorization token which can be used
      to gain access to resources on the FHIR server.

      These tests specifically verify a system's support for [confidential
      asymmetric client
      authentication](https://hl7.org/fhir/smart-app-launch/STU2/client-confidential-asymmetric.html),
      which is not verified in earlier scenarios.

      In this scenario, Inferno will redirect the user to the the authorization endpoint so that
      they may provide any required credentials and authorize the application.
      Upon successful authorization, Inferno will exchange the authorization
      code provided for an access token.

      For more information on the #{title}:

      * [Standalone Launch Sequence](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
    )

    input_instructions %(
      Register Inferno as a standalone application using the following information:

      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`
      * JWKS URI (`jku`): `#{Inferno::Application[:base_url]}/custom/smart_stu2/.well-known/jwks.json`

      Enter in the appropriate scopes to enable access to the Patient resource.
      In addition, support for the OpenID Connect (openid fhirUser), refresh
      tokens (offline_access), and patient context (launch/patient) are
      required.
    )
    id :g10_asymmetric_launch
    run_as_group

    config(
      inputs: {
        smart_auth_info: {
          name: :asymmetric_smart_auth_info,
          title: 'Asymmetric Launch Credentials',
          options: {
            mode: 'auth',
            components: [
              {
                name: :auth_type,
                default: 'asymmetric',
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
              },
              {
                name: :jwks,
                locked: true
              }
            ]
          }
        },
        code: {
          name: :asymmetric_code
        },
        state: {
          name: :asymmetric_state
        },
        received_scopes: {
          name: :asymmetric_received_scopes
        },
        patient_id: {
          name: :asymmetric_patient_id
        }
      },
      outputs: {
        code: { name: :asymmetric_code },
        encounter_id: { name: :asymmetric_encounter_id },
        id_token: { name: :asymmetric_id_token },
        intent: { name: :asymmetric_intent },
        patient_id: { name: :asymmetric_patient_id },
        received_scopes: { name: :asymmetric_received_scopes },
        smart_auth_info: { name: :asymmetric_smart_auth_info },
        state: { name: :asymmetric_state }
      },
      requests: {
        redirect: { name: :asymmetric_redirect },
        token: { name: :asymmetric_token }
      }
    )

    group from: :smart_discovery_stu2,
          required_suite_options: G10Options::SMART_2_REQUIREMENT
    group from: :smart_discovery_stu2_2, # rubocop:disable Naming/VariableNumber
          required_suite_options: G10Options::SMART_2_2_REQUIREMENT

    group from: :smart_standalone_launch_stu2 do
      required_suite_options(G10Options::SMART_2_REQUIREMENT)
      test from: :g10_patient_context

      test do
        title 'OAuth token exchange response contains OpenID Connect id_token'
        description %(
        This test requires that an OpenID Connect id_token is provided to
        demonstrate authentication capabilies for asymmetric clients.
      )
        id :g10_asymmetric_launch_id_token

        input :id_token,
              name: :asymmetric_id_token,
              locked: true,
              optional: true

        run do
          assert id_token.present?, 'Token response did not provide an id_token as required.'
        end
      end
    end

    group from: :smart_standalone_launch_stu2_2 do # rubocop:disable Naming/VariableNumber
      required_suite_options(G10Options::SMART_2_2_REQUIREMENT)
      test from: :g10_patient_context

      test do
        title 'OAuth token exchange response contains OpenID Connect id_token'
        description %(
        This test requires that an OpenID Connect id_token is provided to
        demonstrate authentication capabilies for asymmetric clients.
      )
        id :g10_asymmetric_launch_id_token

        input :id_token,
              name: :asymmetric_id_token,
              locked: true,
              optional: true

        run do
          assert id_token.present?, 'Token response did not provide an id_token as required.'
        end
      end
    end

    group from: :g10_token_refresh_stu2 do
      id :g10_smart_asymmetric_token_refresh

      test from: :g10_patient_context do
        config(
          options: {
            refresh_test: true
          }
        )
        uses_request :token_refresh
      end

      test from: :g10_invalid_token_refresh
    end
  end
end
