require_relative 'base_token_refresh_group'
require_relative 'patient_context_test'
require_relative 'smart_invalid_token_refresh_test'
require_relative 'smart_scopes_test'
require_relative 'unauthorized_access_test'
require_relative 'unrestricted_resource_type_access_group'
require_relative 'well_known_capabilities_test'
require_relative 'incorrectly_permitted_tls_versions_messages_setup_test'

module ONCCertificationG10TestKit
  class SmartStandalonePatientAppGroup < Inferno::TestGroup
    title 'Standalone Patient App - Full Access'
    short_title 'Standalone Patient App'

    input_instructions %(
      Register Inferno as a standalone application using the following information:

      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      Enter in the appropriate scope to enable patient-level access to all
      relevant resources. In addition, support for the OpenID Connect (openid
      fhirUser), refresh tokens (offline_access), and patient context
      (launch/patient) are required.
    )

    description %(
        This scenario verifies the ability of a system to perform a single
        SMART App Launch.  Specifically, this scenario performs a Patient
        Standalone Launch to a SMART on FHIR confidential client with a patient
        context, refresh token, OpenID Connect (OIDC) identity token, and use
        the GET HTTP method for code exchange.

        After launch, a simple Patient resource read is performed on the patient
        in context. The access token is then refreshed, and the Patient resource
        is read using the new access token to ensure that the refresh was
        successful. The authentication information provided by OpenID Connect is
        decoded and validated, and simple queries are performed to ensure that
        access is granted to all USCDI data elements.

        Prior to running the scenario, register Inferno as a confidential client
        with the following information:

        * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

        The following implementation specifications are relevant to this scenario:

        * [SMART on FHIR
          (STU1)](http://www.hl7.org/fhir/smart-app-launch/1.0.0/)
        * [SMART on FHIR
          (STU2)](http://hl7.org/fhir/smart-app-launch/STU2)
        * [OpenID Connect
          (OIDC)](https://openid.net/specs/openid-connect-core-1_0.html)
      )
    id :g10_smart_standalone_patient_app
    run_as_group

    config(
      inputs: {
        smart_auth_info: {
          name: :standalone_smart_auth_info,
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
                type: 'textarea'
              },
              {
                name: :auth_request_method,
                default: 'GET',
                locked: true
              },
              {
                name: :use_discovery,
                locked: true
              }
            ]
          }
        }
      }
    )

    group from: :smart_discovery do
      required_suite_options(G10Options::SMART_1_REQUIREMENT)

      config(
        outputs: {
          smart_auth_info: { name: :standalone_smart_auth_info }
        }
      )

      test from: 'g10_smart_well_known_capabilities',
           config: {
             options: {
               required_capabilities: [
                 'launch-standalone',
                 'client-public',
                 'client-confidential-symmetric',
                 'sso-openid-connect',
                 'context-standalone-patient',
                 'permission-offline',
                 'permission-patient'
               ]
             }
           }

      test do
        required_suite_options(G10Options::US_CORE_7_REQUIREMENT)

        id :g10_us_core_7_smart_version_check
        title 'US Core 7 requires SMART App Launch 2.0.0 or above'
        description %(
          The [US Core 7 SMART on FHIR Obligations and
          Capabilities](https://hl7.org/fhir/us/core/STU7/scopes.html) require
          SMART App Launch 2.0.0 or above, so systems can not certify with US
          Core 7 and SMART App Launch 1.0.0.

          The [Test
          Procedure](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services)
          also states in **Paragraph (g)(10)(v)(A) – Authentication and
          authorization for patient and user scopes**:

          > Note: US Core 7.0.0 must be tested with SMART App Launch 2.0.0 or
            above.
        )

        run do
          assert false, 'US Core 7 is not eligible for certification with SMART App Launch 1.0.0. ' \
                        'Start a new session with SMART App Launch 2.0.0 or higher.'
        end
      end
    end

    # group from: :smart_discovery_stu2 do
    #   required_suite_options(G10Options::SMART_2_REQUIREMENT)

    #   test from: 'g10_smart_well_known_capabilities',
    #        config: {
    #          options: {
    #            required_capabilities: [
    #              'launch-standalone',
    #              'client-public',
    #              'client-confidential-symmetric',
    #              'client-confidential-asymmetric',
    #              'sso-openid-connect',
    #              'context-standalone-patient',
    #              'permission-offline',
    #              'permission-patient',
    #              'authorize-post',
    #              'permission-v2',
    #              'permission-v1'
    #            ]
    #          }
    #        }
    # end

    # group from: :smart_discovery_stu2_2 do # rubocop:disable Naming/VariableNumber
    #   required_suite_options(G10Options::SMART_2_2_REQUIREMENT)
    #   test from: 'g10_smart_well_known_capabilities',
    #        config: {
    #          options: {
    #            required_capabilities: [
    #              'launch-standalone',
    #              'client-public',
    #              'client-confidential-symmetric',
    #              'client-confidential-asymmetric',
    #              'sso-openid-connect',
    #              'context-standalone-patient',
    #              'permission-offline',
    #              'permission-patient',
    #              'authorize-post',
    #              'permission-v2',
    #              'permission-v1'
    #            ]
    #          }
    #        }
    # end

    group from: :smart_standalone_launch do
      required_suite_options(G10Options::SMART_1_REQUIREMENT)

      title 'Standalone Launch With Patient Scope'
      description %(
        # Background

        The [Standalone
        Launch Sequence](http://hl7.org/fhir/smart-app-launch/1.0.0/index.html#standalone-launch-sequence)
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
          Sequence](http://hl7.org/fhir/smart-app-launch/1.0.0/index.html#standalone-launch-sequence)
      )

      config(
        inputs: {
          smart_auth_info: {
            name: :standalone_smart_auth_info,
            options: {
              components: [
                {
                  name: :requested_scopes,
                  default: %(
                    launch/patient openid fhirUser offline_access
                    patient/Medication.read patient/AllergyIntolerance.read
                    patient/CarePlan.read patient/CareTeam.read
                    patient/Condition.read patient/Device.read
                    patient/DiagnosticReport.read patient/DocumentReference.read
                    patient/Encounter.read patient/Goal.read
                    patient/Immunization.read patient/Location.read
                    patient/MedicationRequest.read patient/Observation.read
                    patient/Organization.read patient/Patient.read
                    patient/Practitioner.read patient/Procedure.read
                    patient/Provenance.read patient/PractitionerRole.read
                  ).gsub(/\s{2,}/, ' ').strip
                }
              ]
            }
          }
        }
      )

      test from: :g10_smart_scopes do
        config(
          inputs: {
            received_scopes: { name: :standalone_received_scopes }
          },
          options: {
            scope_version: :v1,
            required_scope_type: 'patient',
            required_scopes: ['openid', 'fhirUser', 'launch/patient', 'offline_access']
          }
        )
      end

      test from: :g10_unauthorized_access,
           config: {
             inputs: {
               patient_id: { name: :standalone_patient_id }
             }
           }

      test from: :g10_patient_context,
           config: {
             inputs: {
               patient_id: { name: :standalone_patient_id },
               smart_auth_info: { name: :standalone_smart_auth_info }
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

    # group from: :smart_standalone_launch_stu2,
    #       config: {
    #         inputs: {
    #           authorization_method: {
    #             name: :standalone_authorization_method,
    #             default: 'get',
    #             locked: true
    #           },
    #           client_auth_type: {
    #             locked: true,
    #             default: 'confidential_symmetric'
    #           }
    #         }
    #       } do
    #   required_suite_options(G10Options::SMART_2_REQUIREMENT)

    #   title 'Standalone Launch With Patient Scope'
    #   description %(
    #     # Background

    #     The [Standalone
    #     Launch Sequence](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
    #     allows an app, like Inferno, to be launched independent of an
    #     existing EHR session. It is one of the two launch methods described in
    #     the SMART App Launch Framework alongside EHR Launch. The app will
    #     request authorization for the provided scope from the authorization
    #     endpoint, ultimately receiving an authorization token which can be used
    #     to gain access to resources on the FHIR server.

    #     # Test Methodology

    #     Inferno will redirect the user to the the authorization endpoint so that
    #     they may provide any required credentials and authorize the application.
    #     Upon successful authorization, Inferno will exchange the authorization
    #     code provided for an access token.

    #     For more information on the #{title}:

    #     * [Standalone Launch
    #       Sequence](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
    #   )

    #   config(
    #     inputs: {
    #       requested_scopes: {
    #         default: %(
    #           launch/patient openid fhirUser offline_access
    #           patient/Medication.rs patient/AllergyIntolerance.rs
    #           patient/CarePlan.rs patient/CareTeam.rs patient/Condition.rs
    #           patient/Device.rs patient/DiagnosticReport.rs
    #           patient/DocumentReference.rs patient/Encounter.rs
    #           patient/Goal.rs patient/Immunization.rs patient/Location.rs
    #           patient/MedicationRequest.rs patient/Observation.rs
    #           patient/Organization.rs patient/Patient.rs
    #           patient/Practitioner.rs patient/Procedure.rs
    #           patient/Provenance.rs patient/PractitionerRole.rs
    #         ).gsub(/\s{2,}/, ' ').strip
    #       }
    #     }
    #   )

    #   test from: :g10_smart_scopes do
    #     config(
    #       inputs: {
    #         requested_scopes: { name: :standalone_requested_scopes },
    #         received_scopes: { name: :standalone_received_scopes }
    #       },
    #       options: {
    #         scope_version: :v2,
    #         required_scope_type: 'patient',
    #         required_scopes: ['openid', 'fhirUser', 'launch/patient', 'offline_access']
    #       }
    #     )
    #   end

    #   test from: :g10_unauthorized_access,
    #        config: {
    #          inputs: {
    #            patient_id: { name: :standalone_patient_id }
    #          }
    #        }

    #   test from: :g10_patient_context,
    #        config: {
    #          inputs: {
    #            patient_id: { name: :standalone_patient_id },
    #            smart_auth_info: { name: :standalone_smart_auth_info }
    #          }
    #        }

    #   tests[0].config(
    #     outputs: {
    #       incorrectly_permitted_tls_versions_messages: {
    #         name: :auth_incorrectly_permitted_tls_versions_messages
    #       }
    #     }
    #   )

    #   tests[3].config(
    #     outputs: {
    #       incorrectly_permitted_tls_versions_messages: {
    #         name: :token_incorrectly_permitted_tls_versions_messages
    #       }
    #     }
    #   )
    # end

    # group from: :smart_standalone_launch_stu2_2, # rubocop:disable Naming/VariableNumber
    #       config: {
    #         inputs: {
    #           use_pkce: {
    #             default: 'true',
    #             locked: true
    #           },
    #           pkce_code_challenge_method: {
    #             locked: true
    #           },
    #           authorization_method: {
    #             name: :standalone_authorization_method,
    #             default: 'get',
    #             locked: true
    #           },
    #           client_auth_type: {
    #             locked: true,
    #             default: 'confidential_symmetric'
    #           }
    #         }
    #       } do
    #   required_suite_options(G10Options::SMART_2_2_REQUIREMENT)
    #   title 'Standalone Launch With Patient Scope'
    #   description %(
    #     # Background

    #     The [Standalone
    #     Launch Sequence](http://hl7.org/fhir/smart-app-launch/STU2.2/app-launch.html#launch-app-standalone-launch)
    #     allows an app, like Inferno, to be launched independent of an
    #     existing EHR session. It is one of the two launch methods described in
    #     the SMART App Launch Framework alongside EHR Launch. The app will
    #     request authorization for the provided scope from the authorization
    #     endpoint, ultimately receiving an authorization token which can be used
    #     to gain access to resources on the FHIR server.

    #     # Test Methodology

    #     Inferno will redirect the user to the the authorization endpoint so that
    #     they may provide any required credentials and authorize the application.
    #     Upon successful authorization, Inferno will exchange the authorization
    #     code provided for an access token.

    #     For more information on the #{title}:

    #     * [Standalone Launch
    #       Sequence](http://hl7.org/fhir/smart-app-launch/STU2.2/app-launch.html#launch-app-standalone-launch)
    #   )

    #   config(
    #     inputs: {
    #       requested_scopes: {
    #         default: %(
    #           launch/patient openid fhirUser offline_access
    #           patient/Medication.rs patient/AllergyIntolerance.rs
    #           patient/CarePlan.rs patient/CareTeam.rs patient/Condition.rs
    #           patient/Device.rs patient/DiagnosticReport.rs
    #           patient/DocumentReference.rs patient/Encounter.rs
    #           patient/Goal.rs patient/Immunization.rs patient/Location.rs
    #           patient/MedicationRequest.rs patient/Observation.rs
    #           patient/Organization.rs patient/Patient.rs
    #           patient/Practitioner.rs patient/Procedure.rs
    #           patient/Provenance.rs patient/PractitionerRole.rs
    #         ).gsub(/\s{2,}/, ' ').strip
    #       }
    #     }
    #   )

    #   test from: :g10_smart_scopes do
    #     config(
    #       inputs: {
    #         requested_scopes: { name: :standalone_requested_scopes },
    #         received_scopes: { name: :standalone_received_scopes }
    #       },
    #       options: {
    #         scope_version: :v22,
    #         required_scope_type: 'patient',
    #         required_scopes: ['openid', 'fhirUser', 'launch/patient', 'offline_access']
    #       }
    #     )
    #   end

    #   test from: :g10_unauthorized_access,
    #        config: {
    #          inputs: {
    #            patient_id: { name: :standalone_patient_id }
    #          }
    #        }

    #   test from: :g10_patient_context,
    #        config: {
    #          inputs: {
    #            patient_id: { name: :standalone_patient_id },
    #            smart_auth_info: { name: :standalone_smart_auth_info }
    #          }
    #        }

    #   tests[0].config(
    #     outputs: {
    #       incorrectly_permitted_tls_versions_messages: {
    #         name: :auth_incorrectly_permitted_tls_versions_messages
    #       }
    #     }
    #   )

    #   tests[3].config(
    #     outputs: {
    #       incorrectly_permitted_tls_versions_messages: {
    #         name: :token_incorrectly_permitted_tls_versions_messages
    #       }
    #     }
    #   )
    # end

    group from: :smart_openid_connect,
          required_suite_options: G10Options::SMART_1_REQUIREMENT,
          config: {
            inputs: {
              id_token: { name: :standalone_id_token },
              smart_auth_info: { name: :standalone_smart_auth_info }
            }
          }

    # group from: :smart_openid_connect,
    #       required_suite_options: G10Options::SMART_2_REQUIREMENT,
    #       id: :smart_openid_connect_stu2,
    #       config: {
    #         inputs: {
    #           id_token: { name: :standalone_id_token },
    #           smart_auth_info: { name: :standalone_smart_auth_info }
    #         }
    #       }

    # group from: :smart_openid_connect_stu2_2, # rubocop:disable Naming/VariableNumber
    #       required_suite_options: G10Options::SMART_2_2_REQUIREMENT,
    #       config: {
    #         inputs: {
    #           id_token: { name: :standalone_id_token },
    #           smart_auth_info: { name: :standalone_smart_auth_info }
    #         }
    #       }

    group from: :g10_token_refresh do
      id :g10_smart_standalone_token_refresh

      config(
        inputs: {
          received_scopes: { name: :standalone_received_scopes }
        },
        outputs: {
          refresh_token: { name: :standalone_refresh_token },
          received_scopes: { name: :standalone_received_scopes },
          access_token: { name: :standalone_access_token },
          token_retrieval_time: { name: :standalone_token_retrieval_time },
          expires_in: { name: :standalone_expires_in },
          smart_auth_info: { name: :standalone_smart_auth_info }
        }
      )

      test from: :g10_patient_context do
        config(
          inputs: {
            patient_id: { name: :standalone_patient_id },
            smart_auth_info: { name: :standalone_smart_auth_info }
          },
          options: {
            refresh_test: true
          }
        )
        uses_request :token_refresh
      end

      test from: :g10_invalid_token_refresh
    end

    group from: :g10_unrestricted_resource_type_access,
          config: {
            inputs: {
              received_scopes: { name: :standalone_received_scopes },
              patient_id: { name: :standalone_patient_id },
              smart_auth_info: { name: :standalone_smart_auth_info }
            }
          }

    test do
      id :g10_standalone_credentials_export
      title 'Set SMART Credentials to Standalone Launch Credentials'

      input :standalone_smart_auth_info, type: 'auth_info'
      input :standalone_patient_id
      output :smart_auth_info, :patient_id

      run do
        output smart_auth_info: standalone_smart_auth_info.to_s,
               patient_id: standalone_patient_id
      end
    end

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
