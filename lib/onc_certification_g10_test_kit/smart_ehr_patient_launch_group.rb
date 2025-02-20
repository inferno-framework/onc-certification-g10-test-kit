require_relative 'patient_scope_test'

module ONCCertificationG10TestKit
  class SMARTEHRPatientLaunchGroup < SMARTAppLaunch::EHRLaunchGroup
    title 'EHR Launch with Patient Scopes'
    description %(
      Systems are required to support the `permission-patient` capability as
      part of the [Clinician Access for EHR Launch Capability
      Set.](http://hl7.org/fhir/smart-app-launch/1.0.0/conformance/index.html#clinician-access-for-ehr-launch)
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
        EHR](http://hl7.org/fhir/smart-app-launch/1.0.0/scopes-and-launch-context/index.html#apps-that-launch-from-the-ehr)
    )
    id :g10_ehr_patient_launch
    run_as_group

    config(
      inputs: {
        smart_auth_info: {
          name: :ehr_patient_smart_auth_info,
          title: 'EHR Launch with Patient Scopes Credentials',
          options: {
            mode: 'auth',
            components: [
              {
                name: :auth_type,
                default: 'symmetric',
                locked: true
              },
              {
                name: :requested_scopes,
                default: 'launch openid fhirUser offline_access patient/Patient.read',
                locked: true
              },
              {
                name: :use_discovery,
                locked: true
              }
            ]
          }
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
        patient_id: {
          name: :ehr_patient_patient_id
        }
      },
      outputs: {
        launch: { name: :ehr_patient_launch },
        code: { name: :ehr_patient_code },
        state: { name: :ehr_patient_state },
        id_token: { name: :ehr_patient_id_token },
        patient_id: { name: :ehr_patient_patient_id },
        encounter_id: { name: :ehr_patient_encounter_id },
        received_scopes: { name: :ehr_patient_received_scopes },
        intent: { name: :ehr_patient_intent },
        smart_auth_info: { name: :ehr_patient_smart_auth_info }
      },
      requests: {
        redirect: { name: :ehr_patient_redirect },
        token: { name: :ehr_patient_token }
      }
    )

    test from: :g10_patient_context

    test from: :g10_patient_scope,
         config: {
           options: {
             scope_version: :v1
           }
         }

    test from: :well_known_endpoint

    # Move the well-known endpoint test to the beginning
    children.prepend(children.pop)
  end
end
