module ONCCertificationG10TestKit
  class TokenRevocationGroup < Inferno::TestGroup
    title 'Token Revocation'
    description %(
      This scenario verifies the ability of the system to revoke access granted to
      an application at the direction of a patient.  Access to the application
      must be revoked within one hour of the patient's request.
    )
    id :g10_token_revocation
    run_as_group

    input_order :token_revocation_attestation,
                :token_revocation_notes,
                :standalone_patient_id,
                :url

    config(
      inputs: {
        smart_auth_info: {
          title: 'Revoked Bearer Token',
          description: 'Prior to the test, please revoke this bearer token from patient standalone launch.',
          options: {
            mode: 'access',
            components: [
              Inferno::DSL::AuthInfo.default_auth_type_component_without_backend_services,
              {
                name: :client_id,
                locked: true
              },
              {
                name: :client_secret,
                locked: true
              },
              {
                name: :refresh_token,
                optional: false
              },
              {
                name: :token_url,
                optional: false
              },
              {
                name: :jwks,
                locked: true
              }
            ]
          }
        }
      }
    )

    test do
      title 'Health IT developer demonstrated the ability of the Health IT Module to revoke tokens within one hour of a patient\'s request.' # rubocop:disable Layout/LineLength
      description %(
        Health IT developer demonstrated the ability of the Health IT Module /
        authorization server to revoke tokens at a patient's direction within one
        hour of the request.
      )

      input :token_revocation_attestation,
            title: 'The Health IT developer demonstrated a patient\'s request for revoking the tokens provided during the patient standalone launch within the last hour', # rubocop:disable Layout/LineLength
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :token_revocation_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert token_revocation_attestation == 'true',
               'Health IT Module did not demonstrate a patient\'s request for revoking the tokens within the last hour.'
        pass token_revocation_notes if token_revocation_notes.present?
      end
    end

    test do
      title 'Access to Patient resource returns unauthorized after token revocation.'
      description %(
        This test checks that the Patient resource returns unuathorized after token revocation.
      )

      input :url,
            title: 'FHIR Endpoint',
            description: 'URL of the FHIR endpoint used by standalone applications'
      input :patient_id,
            name: :standalone_patient_id,
            title: 'Patient ID',
            description: 'Patient ID associated with revoked tokens provided as context in the patient standalone launch. This will be used to verify access is no longer granted using the revoked token.' # rubocop:disable Layout/LineLength
      input :smart_auth_info, type: :auth_info

      fhir_client :revoked_token do
        url :url
        auth_info :smart_auth_info
      end

      run do
        skip_if patient_id.blank?,
                'Patient ID not provided to test. The patient ID is typically provided ' \
                'during a SMART launch context.'
        skip_if smart_auth_info.access_token.blank?,
                'Bearer token not provided. This test verifies that the bearer token can ' \
                'no longer be used to access a Patient resource.'

        fhir_read(:patient, patient_id, client: :revoked_token)

        assert_response_status([401, 403, 404])
      end
    end

    test do
      title 'Token refresh fails after token revocation.'
      description %(
        This test checks that refreshing token fails after token revocation.
      )

      input :smart_auth_info, type: :auth_info

      run do
        skip_if smart_auth_info.refresh_token.blank?,
                'Refresh token not provided to test.'
        oauth2_params = {
          'grant_type' => 'refresh_token',
          'refresh_token' => smart_auth_info.refresh_token
        }
        client_credentials = "#{smart_auth_info.client_id}:#{smart_auth_info.client_secret}"
        oauth2_headers = {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Authorization' => "Basic #{Base64.strict_encode64(client_credentials)}"
        }

        post(smart_auth_info.token_url, body: oauth2_params, headers: oauth2_headers)

        assert_response_status([400, 401])
      end
    end
  end
end
