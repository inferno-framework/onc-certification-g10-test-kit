require_relative 'patient_scope_test'

module ONCCertificationG10TestKit
  class SMARTEHRPatientLaunchGroupSTU22 < SMARTAppLaunch::EHRLaunchGroupSTU22
    title 'EHR Launch with Patient Scopes'
    description %(
      Systems are required to support the `permission-patient` capability as
      part of the [Clinician Access for EHR Launch Capability
      Set.](http://hl7.org/fhir/smart-app-launch/STU2.2/conformance.html#clinician-access-for-ehr-launch)
      Previous scenarios do not verify this specific combination of capabilies.

      Additionally, if an application launched from an EHR requests and is
      granted a clinical scope restricted to a single patient, the EHR SHALL
      establish a patient in context.

      Register Inferno as an EHR-launched application using patient-level scopes
      and the following URIs:

      * Launch URI: `#{SMARTAppLaunch::AppLaunchTest.config.options[:launch_uri]}`
      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      In this scenario, Inferno will attempt an EHR Launch with a clinical scope restricted to a
      single patient and verify that a patient-level scope is granted and a
      patient id is received.

      For more information on the #{title}

      * [Apps that launch from the
        EHR](http://hl7.org/fhir/smart-app-launch/STU2.2/scopes-and-launch-context.html#apps-that-launch-from-the-ehr)
    )
    id :g10_ehr_patient_launch_stu2_2 # rubocop:disable Naming/VariableNumber
    run_as_group

    config(
      inputs: {
        client_id: {
          name: :ehr_patient_client_id
        },
        client_secret: {
          name: :ehr_patient_client_secret,
          optional: false
        },
        requested_scopes: {
          name: :ehr_patient_requested_scopes,
          default: 'launch openid fhirUser offline_access patient/Patient.rs',
          locked: true
        },
        code: {
          name: :ehr_patient_code
        },
        state: {
          name: :ehr_patient_state
        },
        launch: {
          name: :ehr_patient_launch
        },
        received_scopes: {
          name: :ehr_patient_received_scopes
        },
        smart_credentials: {
          name: :ehr_patient_smart_credentials
        },
        smart_authorization_url: {
          title: 'OAuth 2.0 Authorize Endpoint',
          description: 'OAuth 2.0 Authorize Endpoint provided during the EHR launch'
        },
        smart_token_url: {
          title: 'OAuth 2.0 Token Endpoint',
          description: 'OAuth 2.0 Token Endpoint provided during the EHR launch'
        },
        client_auth_type: {
          locked: true,
          default: 'confidential_symmetric'
        }
      },
      outputs: {
        launch: { name: :ehr_patient_launch },
        code: { name: :ehr_patient_code },
        token_retrieval_time: { name: :ehr_patient_token_retrieval_time },
        state: { name: :ehr_patient_state },
        id_token: { name: :ehr_patient_id_token },
        refresh_token: { name: :ehr_patient_refresh_token },
        access_token: { name: :ehr_patient_access_token },
        expires_in: { name: :ehr_patient_expires_in },
        patient_id: { name: :ehr_patient_patient_id },
        encounter_id: { name: :ehr_patient_encounter_id },
        received_scopes: { name: :ehr_patient_received_scopes },
        requested_scopes: { name: :ehr_patient_requested_scopes },
        intent: { name: :ehr_patient_intent },
        smart_credentials: { name: :ehr_patient_smart_credentials }
      },
      requests: {
        redirect: { name: :ehr_patient_redirect },
        token: { name: :ehr_patient_token }
      }
    )

    input_order :url,
                :ehr_patient_client_id,
                :ehr_patient_client_secret,
                :smart_authorization_url,
                :smart_token_url,
                :ehr_patient_requested_scopes,
                :authorization_method,
                :use_pkce,
                :pkce_code_challenge_method,
                :client_auth_type

    test from: :g10_patient_context,
         config: {
           inputs: {
             patient_id: { name: :ehr_patient_patient_id },
             smart_credentials: { name: :ehr_patient_smart_credentials }
           }
         }

    test from: :g10_patient_scope,
         config: {
           options: {
             scope_version: :v22
           }
         }

    children.each do |child|
      child.inputs.delete(:client_auth_encryption_method)
    end
  end
end
