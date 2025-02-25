require_relative 'base_token_refresh_group'
require_relative 'scope_constants'
require_relative 'smart_invalid_token_refresh_test'
require_relative 'smart_scopes_test'
require_relative 'unauthorized_access_test'
require_relative 'well_known_capabilities_test'
require_relative 'encounter_context_test'

module ONCCertificationG10TestKit
  class SmartEHRPractitionerAppGroup < Inferno::TestGroup
    include ScopeConstants

    title 'EHR Practitioner App'
    short_title 'EHR Practitioner App'
    input_instructions %(
      Register Inferno as an EHR-launched application using the following information:

      * Launch URI: `#{SMARTAppLaunch::AppLaunchTest.config.options[:launch_uri]}`
      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      Enter in the appropriate scope to enable user-level access to all relevant
      resources. If using SMART v2, v2-style scopes must be used. In addition,
      support for the OpenID Connect (openid fhirUser), refresh tokens
      (offline_access), and EHR context (launch) are required. This test expects
      that the EHR will launch the application with a patient context.

      After submit is pressed, Inferno will wait for the system under test to launch
      the application.
    )

    description %(
      This scenario verifies the ability of a system to perform a single EHR
      Launch.  Specifically, this scenario performs an EHR launch to a SMART on FHIR
      confidential client with patient context, refresh token, OpenID Connect
      (OIDC) identity token, and (SMART v2 only) use the POST HTTP method for
      code exchange.

      After launch, a simple Patient resource read is performed on the patient
      in context. The access token is then refreshed, and the Patient resource
      is read using the new access token to ensure that the refresh was
      successful. Finally, the authentication information provided by OpenID
      Connect is decoded and validated.

      Prior to running this scenario, register Inferno as an EHR-launched confidential
      client with the following information:

      Prior to running this test, register Inferno as an EHR-launched
      application using the following information:

      * Launch URI: `#{SMARTAppLaunch::AppLaunchTest.config.options[:launch_uri]}`
      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      For EHRs that use Internet Explorer 11 to display embedded apps,
      please review [instructions on how to complete the EHR Practitioner App
      test](https://github.com/onc-healthit/onc-certification-g10-test-kit/wiki/Completing-EHR-Practitioner-App-test-in-Internet-Explorer/).

      The following implementation specifications are relevant to this scenario:

      * [SMART on FHIR
        (STU1)](http://www.hl7.org/fhir/smart-app-launch/1.0.0/)
      * [SMART on FHIR
        (STU2)](http://hl7.org/fhir/smart-app-launch/STU2)
      * [OpenID Connect
        (OIDC)](https://openid.net/specs/openid-connect-core-1_0.html)
    )
    id :g10_smart_ehr_practitioner_app
    run_as_group

    config(
      inputs: {
        smart_auth_info: {
          name: :ehr_smart_auth_info,
          title: 'EHR Launch Credentials',
          options: {
            mode: 'auth',
            components: [
              {
                name: :auth_type,
                default: 'symmetric',
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
          smart_auth_info: { name: :ehr_smart_auth_info }
        }
      )

      test from: 'g10_smart_well_known_capabilities',
           config: {
             options: {
               required_capabilities: [
                 'launch-ehr',
                 'client-confidential-symmetric',
                 'sso-openid-connect',
                 'context-banner',
                 'context-style',
                 'context-ehr-patient',
                 'permission-offline',
                 'permission-user'
               ]
             }
           }
    end

    group from: :smart_discovery_stu2 do
      required_suite_options(G10Options::SMART_2_REQUIREMENT)

      config(
        outputs: {
          smart_auth_info: { name: :ehr_smart_auth_info }
        }
      )

      test from: 'g10_smart_well_known_capabilities',
           config: {
             options: {
               required_capabilities: [
                 'launch-ehr',
                 'client-confidential-symmetric',
                 'client-confidential-asymmetric',
                 'sso-openid-connect',
                 'context-banner',
                 'context-style',
                 'context-ehr-patient',
                 'permission-offline',
                 'permission-user',
                 'authorize-post',
                 'permission-v2',
                 'permission-v1'
               ]
             }
           }
    end

    group from: :smart_discovery_stu2_2 do # rubocop:disable Naming/VariableNumber
      required_suite_options(G10Options::SMART_2_2_REQUIREMENT)

      config(
        outputs: {
          smart_auth_info: { name: :ehr_smart_auth_info }
        }
      )

      test from: 'g10_smart_well_known_capabilities',
           config: {
             options: {
               required_capabilities: [
                 'launch-ehr',
                 'client-confidential-symmetric',
                 'client-confidential-asymmetric',
                 'sso-openid-connect',
                 'context-banner',
                 'context-style',
                 'context-ehr-patient',
                 'permission-offline',
                 'permission-user',
                 'authorize-post',
                 'permission-v2',
                 'permission-v1'
               ]
             }
           }
    end

    group from: :smart_ehr_launch do
      required_suite_options(G10Options::SMART_1_REQUIREMENT)

      title 'EHR Launch With Practitioner Scope'

      config(
        inputs: {
          smart_auth_info: {
            name: :ehr_smart_auth_info,
            options: {
              components: [
                {
                  name: :requested_scopes,
                  default: EHR_SMART_1_SCOPES
                }
              ]
            }
          }
        }
      )

      test from: :g10_smart_scopes do
        title 'User-level access with OpenID Connect and Refresh Token scopes used.'
        config(
          inputs: {
            received_scopes: { name: :ehr_received_scopes }
          },
          options: {
            scope_version: :v1,
            required_scope_type: 'user',
            required_scopes: ['openid', 'fhirUser', 'launch', 'offline_access']
          }
        )
      end

      test from: :g10_unauthorized_access,
           config: {
             inputs: {
               patient_id: { name: :ehr_patient_id }
             }
           }

      test from: :g10_patient_context,
           config: {
             inputs: {
               patient_id: { name: :ehr_patient_id }
             }
           }

      test from: :g10_encounter_context,
           config: {
             inputs: {
               encounter_id: { name: :ehr_encounter_id }
             }
           },
           required_suite_options: G10Options::US_CORE_5_REQUIREMENT

      test from: :g10_encounter_context,
           id: :g10_encounter_context_us_core_6, # rubocop:disable Naming/VariableNumber
           config: {
             inputs: {
               encounter_id: { name: :ehr_encounter_id }
             }
           },
           required_suite_options: G10Options::US_CORE_6_REQUIREMENT

      test from: :g10_encounter_context,
           id: :g10_encounter_context_us_core_7, # rubocop:disable Naming/VariableNumber
           config: {
             inputs: {
               encounter_id: { name: :ehr_encounter_id }
             }
           },
           required_suite_options: G10Options::US_CORE_7_REQUIREMENT

      test do
        title 'Launch context contains smart_style_url which links to valid JSON'
        description %(
          In order to mimic the style of the SMART host more closely, SMART apps
          can check for the existence of this launch context parameter and
          download the JSON file referenced by the URL value.
        )
        id :Test13
        uses_request :token

        run do
          skip_if request.status != 200, 'No token response received'
          assert_valid_json response[:body]

          body = JSON.parse(response[:body])

          assert body['smart_style_url'].present?,
                 'Token response did not contain `smart_style_url`'

          get(body['smart_style_url'])

          assert_response_status(200)
          assert_valid_json(response[:body])
        end
      end

      test do
        title 'Launch context contains need_patient_banner'
        description %(
          `need_patient_banner` is a boolean value indicating whether the app
          was launched in a UX context where a patient banner is required (when
          true) or not required (when false).
        )
        id :Test14
        uses_request :token

        run do
          skip_if request.status != 200, 'No token response received'
          assert_valid_json response[:body]

          body = JSON.parse(response[:body])

          assert body.key?('need_patient_banner'),
                 'Token response did not contain `need_patient_banner`'
        end
      end

      tests[2].config(
        outputs: {
          incorrectly_permitted_tls_versions_messages: {
            name: :auth_incorrectly_permitted_tls_versions_messages
          }
        }
      )

      tests[5].config(
        outputs: {
          incorrectly_permitted_tls_versions_messages: {
            name: :token_incorrectly_permitted_tls_versions_messages
          }
        }
      )
    end

    group from: :smart_ehr_launch_stu2 do
      required_suite_options(G10Options::SMART_2_REQUIREMENT)

      title 'EHR Launch With Practitioner Scope'

      config(
        inputs: {
          smart_auth_info: {
            name: :ehr_smart_auth_info,
            options: {
              components: [
                {
                  name: :requested_scopes,
                  default: EHR_SMART_2_SCOPES
                },
                {
                  name: :auth_request_method,
                  default: 'POST',
                  locked: true
                }
              ]
            }
          }
        }
      )

      test from: :g10_smart_scopes do
        title 'User-level access with OpenID Connect and Refresh Token scopes used.'
        config(
          inputs: {
            received_scopes: { name: :ehr_received_scopes }
          },
          options: {
            scope_version: :v2,
            required_scope_type: 'user',
            required_scopes: ['openid', 'fhirUser', 'launch', 'offline_access']
          }
        )
      end

      test from: :g10_unauthorized_access,
           config: {
             inputs: {
               patient_id: { name: :ehr_patient_id }
             }
           }

      test from: :g10_patient_context,
           config: {
             inputs: {
               patient_id: { name: :ehr_patient_id }
             }
           }

      test from: :g10_encounter_context,
           config: {
             inputs: {
               encounter_id: { name: :ehr_encounter_id }
             }
           },
           required_suite_options: G10Options::US_CORE_5_REQUIREMENT

      test from: :g10_encounter_context,
           id: :g10_encounter_context_us_core_6, # rubocop:disable Naming/VariableNumber
           config: {
             inputs: {
               encounter_id: { name: :ehr_encounter_id }
             }
           },
           required_suite_options: G10Options::US_CORE_6_REQUIREMENT

      test from: :g10_encounter_context,
           id: :g10_encounter_context_us_core_7, # rubocop:disable Naming/VariableNumber
           config: {
             inputs: {
               encounter_id: { name: :ehr_encounter_id }
             }
           },
           required_suite_options: G10Options::US_CORE_7_REQUIREMENT

      test do
        title 'Launch context contains smart_style_url which links to valid JSON'
        description %(
          In order to mimic the style of the SMART host more closely, SMART apps
          can check for the existence of this launch context parameter and
          download the JSON file referenced by the URL value.
        )
        uses_request :token
        id :g10_smart_style_url

        run do
          skip_if request.status != 200, 'No token response received'
          assert_valid_json response[:body]

          body = JSON.parse(response[:body])

          assert body['smart_style_url'].present?,
                 'Token response did not contain `smart_style_url`'

          get(body['smart_style_url'])

          assert_response_status(200)
          assert_valid_json(response[:body])
        end
      end

      test do
        title 'Launch context contains need_patient_banner'
        description %(
          `need_patient_banner` is a boolean value indicating whether the app
          was launched in a UX context where a patient banner is required (when
          true) or not required (when false).
        )
        uses_request :token
        id :g10_smart_need_patient_banner

        run do
          skip_if request.status != 200, 'No token response received'
          assert_valid_json response[:body]

          body = JSON.parse(response[:body])

          assert body.key?('need_patient_banner'),
                 'Token response did not contain `need_patient_banner`'
        end
      end

      tests[2].config(
        outputs: {
          incorrectly_permitted_tls_versions_messages: {
            name: :auth_incorrectly_permitted_tls_versions_messages
          }
        }
      )

      tests[5].config(
        outputs: {
          incorrectly_permitted_tls_versions_messages: {
            name: :token_incorrectly_permitted_tls_versions_messages
          }
        }
      )
    end

    group from: :smart_ehr_launch_stu2_2 do # rubocop:disable Naming/VariableNumber
      required_suite_options(G10Options::SMART_2_2_REQUIREMENT)

      title 'EHR Launch With Practitioner Scope'

      config(
        inputs: {
          smart_auth_info: {
            name: :ehr_smart_auth_info,
            options: {
              components: [
                {
                  name: :requested_scopes,
                  default: EHR_SMART_2_SCOPES
                },
                {
                  name: :auth_request_method,
                  default: 'POST',
                  locked: true
                }
              ]
            }
          }
        }
      )

      test from: :g10_smart_scopes do
        title 'User-level access with OpenID Connect and Refresh Token scopes used.'
        config(
          inputs: {
            received_scopes: { name: :ehr_received_scopes }
          },
          options: {
            scope_version: :v22,
            required_scope_type: 'user',
            required_scopes: ['openid', 'fhirUser', 'launch', 'offline_access']
          }
        )
      end

      test from: :g10_unauthorized_access,
           config: {
             inputs: {
               patient_id: { name: :ehr_patient_id }
             }
           }

      test from: :g10_patient_context,
           config: {
             inputs: {
               patient_id: { name: :ehr_patient_id }
             }
           }

      test from: :g10_encounter_context,
           config: {
             inputs: {
               encounter_id: { name: :ehr_encounter_id }
             }
           },
           required_suite_options: G10Options::US_CORE_5_REQUIREMENT

      test from: :g10_encounter_context,
           id: :g10_encounter_context_us_core_6, # rubocop:disable Naming/VariableNumber
           config: {
             inputs: {
               encounter_id: { name: :ehr_encounter_id }
             }
           },
           required_suite_options: G10Options::US_CORE_6_REQUIREMENT

      test from: :g10_encounter_context,
           id: :g10_encounter_context_us_core_7, # rubocop:disable Naming/VariableNumber
           config: {
             inputs: {
               encounter_id: { name: :ehr_encounter_id }
             }
           },
           required_suite_options: G10Options::US_CORE_7_REQUIREMENT

      test do
        title 'Launch context contains smart_style_url which links to valid JSON'
        description %(
          In order to mimic the style of the SMART host more closely, SMART apps
          can check for the existence of this launch context parameter and
          download the JSON file referenced by the URL value.
        )
        uses_request :token
        id :g10_smart_style_url

        run do
          skip_if request.status != 200, 'No token response received'
          assert_valid_json response[:body]

          body = JSON.parse(response[:body])

          assert body['smart_style_url'].present?,
                 'Token response did not contain `smart_style_url`'

          get(body['smart_style_url'])

          assert_response_status(200)
          assert_valid_json(response[:body])
        end
      end

      test do
        title 'Launch context contains need_patient_banner'
        description %(
          `need_patient_banner` is a boolean value indicating whether the app
          was launched in a UX context where a patient banner is required (when
          true) or not required (when false).
        )
        uses_request :token
        id :g10_smart_need_patient_banner

        run do
          skip_if request.status != 200, 'No token response received'
          assert_valid_json response[:body]

          body = JSON.parse(response[:body])

          assert body.key?('need_patient_banner'),
                 'Token response did not contain `need_patient_banner`'
        end
      end

      tests[2].config(
        outputs: {
          incorrectly_permitted_tls_versions_messages: {
            name: :auth_incorrectly_permitted_tls_versions_messages
          }
        }
      )

      tests[5].config(
        outputs: {
          incorrectly_permitted_tls_versions_messages: {
            name: :token_incorrectly_permitted_tls_versions_messages
          }
        }
      )
    end

    group from: :smart_openid_connect,
          required_suite_options: G10Options::SMART_1_REQUIREMENT,
          config: {
            inputs: {
              id_token: { name: :ehr_id_token },
              smart_auth_info: { name: :ehr_smart_auth_info }
            }
          }

    group from: :smart_openid_connect,
          required_suite_options: G10Options::SMART_2_REQUIREMENT,
          id: :smart_openid_connect_stu2,
          config: {
            inputs: {
              id_token: { name: :ehr_id_token },
              smart_auth_info: { name: :ehr_smart_auth_info }
            }
          }

    group from: :smart_openid_connect_stu2_2, # rubocop:disable Naming/VariableNumber
          required_suite_options: G10Options::SMART_2_2_REQUIREMENT,
          config: {
            inputs: {
              id_token: { name: :ehr_id_token },
              smart_auth_info: { name: :ehr_smart_auth_info }
            }
          }

    group from: :g10_token_refresh do
      id :g10_smart_ehr_token_refresh

      config(
        inputs: {
          received_scopes: { name: :ehr_received_scopes }
        },
        outputs: {
          refresh_token: { name: :ehr_refresh_token },
          received_scopes: { name: :ehr_received_scopes },
          access_token: { name: :ehr_access_token },
          token_retrieval_time: { name: :ehr_token_retrieval_time },
          expires_in: { name: :ehr_expires_in },
          smart_auth_info: { name: :ehr_smart_auth_info }
        }
      )

      test from: :g10_patient_context do
        config(
          inputs: {
            patient_id: { name: :ehr_patient_id }
          },
          options: {
            refresh_test: true
          }
        )
        uses_request :token_refresh
      end

      test from: :g10_invalid_token_refresh
    end

    test do
      id :g10_ehr_credentials_export
      title 'Set SMART Credentials to EHR Launch Credentials'

      input :ehr_smart_auth_info, type: :auth_info
      input :ehr_patient_id
      output :smart_auth_info, :patient_id

      run do
        output smart_auth_info: ehr_smart_auth_info.to_s,
               patient_id: ehr_patient_id
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
