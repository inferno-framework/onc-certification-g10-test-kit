require_relative 'scope_constants'

module ONCCertificationG10TestKit
  class SMARTPublicStandaloneLaunchGroup < SMARTAppLaunch::StandaloneLaunchGroup
    include ScopeConstants

    title 'Public Client Standalone Launch with OpenID Connect'
    short_title 'Public Client Launch'
    input_instructions %(
      Register Inferno as a standalone application using the following information:

      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      Enter in the appropriate scope to enable patient-level access to all
      relevant resources. If using SMART v2, v2-style scopes must be used. In
      addition, support for the OpenID Connect (openid fhirUser), refresh tokens
      (offline_access), and patient context (launch/patient) are required.
    )
    description %(

      This scenario verifies the ability of systems to support public clients
      as described in the SMART App Launch implementation specification.  Previous
      scenarios have not required the system under test to demonstrate this
      specific type of SMART App Launch client.

      Prior to executing this test, register Inferno as a public standalone
      application using the following information:

      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      Inferno will act as a public client redirect the tester to the the
      authorization endpoint so that they may provide any required credentials
      and authorize the application. Upon successful authorization, Inferno will
      exchange the authorization code provided for an access token.

      For more information on the #{title}:

      * [Standalone Launch Sequence](http://hl7.org/fhir/smart-app-launch/1.0.0/index.html#standalone-launch-sequence)
    )
    id :g10_public_standalone_launch
    run_as_group

    config(
      inputs: {
        smart_auth_info: {
          name: :public_smart_auth_info,
          title: 'Public Launch Credentials',
          options: {
            mode: 'auth',
            components: [
              {
                name: :auth_type,
                default: 'public',
                locked: true
              },
              {
                name: :requested_scopes,
                default: STANDALONE_SMART_1_SCOPES
              }
            ]
          }
        },
        url: {
          title: 'Public Launch FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by standalone applications'
        },
        code: {
          name: :public_code
        },
        state: {
          name: :public_state
        },
        patient_id: {
          name: :public_patient_id
        }
      },
      outputs: {
        code: { name: :public_code },
        state: { name: :public_state },
        id_token: { name: :public_id_token },
        patient_id: { name: :public_patient_id },
        encounter_id: { name: :public_encounter_id },
        received_scopes: { name: :public_received_scopes },
        intent: { name: :public_intent },
        smart_auth_info: { name: :public_smart_auth_info }
      },
      requests: {
        redirect: { name: :public_redirect },
        token: { name: :public_token }
      }
    )

    test from: :g10_patient_context

    test do
      title 'OAuth token exchange response contains OpenID Connect id_token'
      description %(
        This test requires that an OpenID Connect id_token is provided to
        demonstrate authentication capabilies for public clients.
      )
      id :g10_public_launch_id_token

      input :id_token,
            name: :public_id_token,
            locked: true,
            optional: true

      run do
        assert id_token.present?, 'Token response did not provide an id_token as required.'
      end
    end

    test from: :well_known_endpoint

    # Move the well-known endpoint test to the beginning
    children.prepend(children.pop)
  end
end
