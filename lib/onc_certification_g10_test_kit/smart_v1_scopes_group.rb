require_relative 'base_token_refresh_group'
require_relative 'patient_context_test'
require_relative 'smart_invalid_token_refresh_test'
require_relative 'smart_scopes_test'
require_relative 'unauthorized_access_test'
require_relative 'unrestricted_resource_type_access_group'
require_relative 'well_known_capabilities_test'
require_relative 'incorrectly_permitted_tls_versions_messages_setup_test'

module ONCCertificationG10TestKit
  class SmartV1ScopesGroup < Inferno::TestGroup
    title 'App Launch with SMART v1 scopes'
    short_title 'Launch with v1 Scopes'

    input_instructions %(
      Register Inferno as a standalone application using the following information:

      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      Enter in the appropriate v1 scopes to enable patient-level access to all
      relevant resources. In addition, support for the OpenID Connect (openid
      fhirUser), refresh tokens (offline_access), and patient context
      (launch/patient) are required.
    )

    description %(
        This scenario verifies the ability of a system to support a
        Standalone Launch when v1 scopes are requested by the client.
        It verifies that systems implement the `permission-v1` capability as required.
        Previous scenarios focus on the use of the `permission-v2` capability,
        and thus a dedicated launch is required to verify that systems
        can support a client that requests `permission-v1` style scopes.

        This scenario does not place any constraints on the form of scopes
        granted.  Systems are free to grant v1-style scopes in response to the
        request for v1-style scopes, as recommended in the [SMART App Launch Guide STU2](http://hl7.org/fhir/smart-app-launch/scopes-and-launch-context.html#scopes-for-requesting-fhir-resources).
        Or they can upgrade them to v2-style scopes.  The scenario only ensures
        that systems can grant access to clients that request v1-style scopes
        and that the client has access to resources as expected.

        All relevant resource types must be granted, in a similar manner to the
        'Standalone Patient App' scenario.

        This scenario expects Inferno to be registered as a 'Confidential
        Symmetric' client.  Systems may either reuse a `client_id` associated
        with Inferno used in a previous scenario, or register Inferno with a new
        `client_id` as a standalone client with the following information:

        * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      )

    id :g10_smart_v1_scopes
    run_as_group

    config(
      inputs: {
        client_secret: {
          optional: false,
          name: :standalone_client_secret
        },
        requested_scopes: {
          name: :v1_requested_scopes,
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
            patient/Specimen.read patient/Coverage.read
            patient/MedicationDispense.read patient/ServiceRequest.read
          ).gsub(/\s{2,}/, ' ').strip
        },
        received_scopes: { name: :v1_received_scopes },
        smart_credentials: { name: :v1_smart_credentials }
      },
      outputs: {
        received_scopes: { name: :v1_received_scopes },
        patient_id: { name: :v1_patient_id }
      }
    )

    input_order :url,
                :standalone_client_id,
                :standalone_client_secret,
                :v1_requested_scopes,
                :use_pkce,
                :pkce_code_challenge_method,
                :standalone_authorization_method,
                :client_auth_type,
                :client_auth_encryption_method

    group from: :smart_discovery_stu2 do
      required_suite_options(G10Options::SMART_2_REQUIREMENT)
      test from: 'g10_smart_well_known_capabilities',
           config: {
             options: {
               required_capabilities: [
                 'launch-standalone',
                 'client-public',
                 'client-confidential-symmetric',
                 'client-confidential-asymmetric',
                 'sso-openid-connect',
                 'context-standalone-patient',
                 'permission-offline',
                 'permission-patient',
                 'authorize-post',
                 'permission-v2',
                 'permission-v1'
               ]
             }
           }
    end
    group from: :smart_discovery_stu2 do
      required_suite_options(G10Options::SMART_2_2_REQUIREMENT)
      id :smart_discovery_stu2_2
      test from: 'g10_smart_well_known_capabilities',
           config: {
             options: {
               required_capabilities: [
                 'launch-standalone',
                 'client-public',
                 'client-confidential-symmetric',
                 'client-confidential-asymmetric',
                 'sso-openid-connect',
                 'context-standalone-patient',
                 'permission-offline',
                 'permission-patient',
                 'authorize-post',
                 'permission-v2',
                 'permission-v1'
               ]
             }
           }
    end

    group from: :smart_standalone_launch_stu2,
          required_suite_options: G10Options::SMART_2_REQUIREMENT,
          config: {
            inputs: {
              use_pkce: {
                default: 'true',
                locked: true
              },
              pkce_code_challenge_method: {
                locked: true
              },
              authorization_method: {
                name: :standalone_authorization_method,
                default: 'get',
                locked: true
              },
              client_auth_type: {
                locked: true,
                default: 'confidential_symmetric'
              }
            },
            outputs: {
              smart_credentials: { name: :v1_smart_credentials }
            }
          } do
      title 'Standalone Launch With Patient Scope'
      description %(
        # Background

        The [Standalone
        Launch Sequence](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
        allows an app, like Inferno, to be launched independent of an
        existing EHR session. It is one of the two launch methods described in
        the SMART App Launch Framework alongside EHR Launch. The app will
        request authorization for the provided scope from the authorization
        endpoint, ultimately receiving an authorization token which can be used
        to gain access to resources on the FHIR server.

        # Test Methodology

        Inferno will redirect the user to the the authorization endpoint so that
        they may provide any required credentials and authorize the application.
        Upon successful authorization, Inferno will exchange the authorization
        code provided for an access token.

        For more information on the #{title}:

        * [Standalone Launch
          Sequence](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
      )

      test from: :g10_smart_scopes do
        config(
          options: {
            requested_scope_version: :v1,
            received_scope_version: :any,
            required_scope_type: 'patient',
            required_scopes: ['openid', 'fhirUser', 'launch/patient', 'offline_access']
          }
        )
      end

      test from: :g10_unauthorized_access,
           config: {
             inputs: {
               patient_id: { name: :v1_patient_id }
             }
           }

      test from: :g10_patient_context,
           config: {
             inputs: {
               patient_id: { name: :v1_patient_id },
               smart_credentials: { name: :v1_smart_credentials }
             }
           }

      tests[0].config(
        outputs: {
          incorrectly_permitted_tls_versions_messages: {
            name: :auth_incorrectly_permitted_tls_versions_messages
          }
        }
      )

      tests[3].config(
        outputs: {
          incorrectly_permitted_tls_versions_messages: {
            name: :token_incorrectly_permitted_tls_versions_messages
          }
        }
      )
    end
    group from: :smart_standalone_launch_stu2_2,
          required_suite_options: G10Options::SMART_2_2_REQUIREMENT,
          config: {
            inputs: {
              use_pkce: {
                default: 'true',
                locked: true
              },
              pkce_code_challenge_method: {
                locked: true
              },
              authorization_method: {
                name: :standalone_authorization_method,
                default: 'get',
                locked: true
              },
              client_auth_type: {
                locked: true,
                default: 'confidential_symmetric'
              }
            },
            outputs: {
              smart_credentials: { name: :v1_smart_credentials }
            }
          } do
      title 'Standalone Launch With Patient Scope'
      description %(
        # Background

        The [Standalone
        Launch Sequence](http://hl7.org/fhir/smart-app-launch/STU2.2/app-launch.html#launch-app-standalone-launch)
        allows an app, like Inferno, to be launched independent of an
        existing EHR session. It is one of the two launch methods described in
        the SMART App Launch Framework alongside EHR Launch. The app will
        request authorization for the provided scope from the authorization
        endpoint, ultimately receiving an authorization token which can be used
        to gain access to resources on the FHIR server.

        # Test Methodology

        Inferno will redirect the user to the the authorization endpoint so that
        they may provide any required credentials and authorize the application.
        Upon successful authorization, Inferno will exchange the authorization
        code provided for an access token.

        For more information on the #{title}:

        * [Standalone Launch
          Sequence](http://hl7.org/fhir/smart-app-launch/STU2.2/app-launch.html#launch-app-standalone-launch)
      )

      test from: :g10_smart_scopes do
        config(
          options: {
            requested_scope_version: :v1,
            received_scope_version: :any,
            required_scope_type: 'patient',
            required_scopes: ['openid', 'fhirUser', 'launch/patient', 'offline_access']
          }
        )
      end

      test from: :g10_unauthorized_access,
           config: {
             inputs: {
               patient_id: { name: :v1_patient_id }
             }
           }

      test from: :g10_patient_context,
           config: {
             inputs: {
               patient_id: { name: :v1_patient_id },
               smart_credentials: { name: :v1_smart_credentials }
             }
           }

      tests[0].config(
        outputs: {
          incorrectly_permitted_tls_versions_messages: {
            name: :auth_incorrectly_permitted_tls_versions_messages
          }
        }
      )

      tests[3].config(
        outputs: {
          incorrectly_permitted_tls_versions_messages: {
            name: :token_incorrectly_permitted_tls_versions_messages
          }
        }
      )
    end

    group from: :g10_unrestricted_resource_type_access,
          config: {
            inputs: {
              received_scopes: { name: :v1_received_scopes },
              patient_id: { name: :v1_patient_id },
              smart_credentials: { name: :v1_smart_credentials }
            }
          }

    test from: :g10_incorrectly_permitted_tls_versions_messages_setup,
         id: :g10_auth_incorrectly_permitted_tls_versions_messages_setup,
         config: {
           inputs: {
             incorrectly_permitted_tls_versions_messages: {
               name: :auth_incorrectly_permitted_tls_versions_messages
             }
           }
         }

    test from: :g10_incorrectly_permitted_tls_versions_messages_setup,
         id: :g10_token_incorrectly_permitted_tls_versions_messages_setup,
         config: {
           inputs: {
             incorrectly_permitted_tls_versions_messages: {
               name: :token_incorrectly_permitted_tls_versions_messages
             }
           }
         }
  end
end
