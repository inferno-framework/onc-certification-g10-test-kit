require_relative 'g10_options'

module ONCCertificationG10TestKit
  class VisualInspectionAndAttestationsGroup < Inferno::TestGroup
    title 'Visual Inspection and Attestation'
    short_title 'Visual Inspection'
    description 'Verify conformance to portions of the test procedure that are not automated.'
    id :g10_visual_inspection_and_attestations
    run_as_group

    test do
      title 'Health IT Module demonstrated support for application registration for single patients.'
      description %(
        Health IT Module demonstrated support for application registration for
        single patients.
      )
      id 'Test01'
      input :single_patient_registration_supported,
            title: 'Health IT Module demonstrated support for application registration for single patients.',
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
      input :single_patient_registration_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert single_patient_registration_supported == 'true',
               'Health IT Module did not demonstrate support for application registration for single patients.'
        pass single_patient_registration_notes if single_patient_registration_notes.present?
      end
    end

    test do
      title 'Health IT Module demonstrated support for application registration for multiple patients.'
      description %(
        Health IT Module demonstrated support for supports application
        registration for multiple patients.
      )
      id 'Test02'
      input :multiple_patient_registration_supported,
            title: 'Health IT Module demonstrated support for application registration for multiple patients.',
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
      input :multiple_patient_registration_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert multiple_patient_registration_supported == 'true',
               'Health IT Module did not demonstrate support for application registration for multiple patients.'
        pass multiple_patient_registration_notes if multiple_patient_registration_notes.present?
      end
    end

    test do
      title 'Health IT Module demonstrated a graphical user interface for user to authorize FHIR resources.'
      description %(
        Health IT Module demonstrated a graphical user interface for user to
        authorize FHIR resources
      )
      id 'Test03'
      input :resource_authorization_gui_supported,
            title: 'Health IT Module demonstrated a graphical user interface for user to authorize FHIR resources.',
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
      input :resource_authorization_gui_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert resource_authorization_gui_supported == 'true',
               'Health IT Module did not demonstrate a graphical user interface for user to authorize FHIR resources'
        pass resource_authorization_gui_notes if resource_authorization_gui_notes.present?
      end
    end

    test do
      title 'Health IT Module informed patient when "offline_access" scope is being granted during authorization.'
      description %(
        Health IT Module informed patient when "offline_access" scope is being
        granted during authorization.
      )
      id 'Test04'
      input :offline_access_notification_supported,
            title: 'Health IT Module informed patient when "offline_access" scope is being granted during authorization.', # rubocop:disable Layout/LineLength
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
      input :offline_access_notification_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert offline_access_notification_supported == 'true',
               'Health IT Module did not inform patient when offline access scope ' \
               'is being granted during authorization.'
        pass offline_access_notification_notes if offline_access_notification_notes.present?
      end
    end

    test do
      title 'Health IT Module attested that it is capable of issuing refresh tokens ' \
            'that are valid for a period of no shorter than three months.'
      description %(
        Health IT Module attested that it is capable of issuing refresh tokens
        that are valid for a period of no shorter than three months.

        This attestation is necessary because automated tests cannot determine how long
        the refresh token remains valid.
      )
      id 'Test05'
      input :refresh_token_period_attestation,
            title: 'Health IT Module attested that it is capable of issuing refresh tokens that are valid for a period of no shorter than three months.', # rubocop:disable Layout/LineLength
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
      input :refresh_token_period_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert refresh_token_period_attestation == 'true',
               'Health IT Module did not attest that it is capable of issuing refresh tokens ' \
               'that are valid for a period of no shorter than three months.'
        pass refresh_token_period_notes if refresh_token_period_notes.present?
      end
    end

    test do
      required_suite_options G10Options::SMART_1_REQUIREMENT
      title 'Health IT developer demonstrated the ability of the Health IT Module / ' \
            'authorization server to validate token it has issued.'
      description %(
        Health IT developer demonstrated the ability of the Health IT Module /
        authorization server to validate token it has issued.

        This is a functional requirement that requires manual inspection because
        SMART App Launch STU1 does not require a standard approach to token
        introspection.
      )
      id 'Test06'
      input :token_validation_support,
            title: 'Health IT developer demonstrated the ability of the Health IT Module / authorization server to validate token it has issued.', # rubocop:disable Layout/LineLength
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
      input :token_validation_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert token_validation_support == 'true',
               'Health IT Module did not demonstrate the ability of the Health IT Module / ' \
               'authorization server to validate token it has issued'
        pass token_validation_notes if token_validation_notes.present?
      end
    end

    test do
      title 'Tester verifies that all information is accurate and without omission.'
      description %(
        Tester verifies that all information is accurate and without omission.
      )
      id 'Test07'
      input :information_accuracy_attestation,
            title: 'Tester verifies that all information is accurate and without omission.',
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
      input :information_accuracy_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert information_accuracy_attestation == 'true',
               'Tester did not verify that all information is accurate and without omission.'
        pass information_accuracy_notes if information_accuracy_notes.present?
      end
    end

    test do
      title 'Information returned no greater than scopes pre-authorized for multi-patient queries.'
      description %(
        Information returned no greater than scopes pre-authorized for
        multi-patient queries.
      )
      id 'Test08'
      input :multi_patient_scopes_attestation,
            title: 'Information returned no greater than scopes pre-authorized for multi-patient queries.',
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
      input :multi_patient_scopes_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert multi_patient_scopes_attestation == 'true',
               'Tester did not verify that all information is accurate and without omission.'
        pass multi_patient_scopes_notes if multi_patient_scopes_notes.present?
      end
    end

    test do
      title 'Health IT developer demonstrated the documentation is available at a publicly accessible URL.'
      description %(
        Health IT developer demonstrated the documentation is available at a
        publicly accessible URL.
      )
      id 'Test09'
      input :developer_documentation_attestation,
            title: 'Health IT developer demonstrated the documentation is available at a publicly accessible URL.',
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
      input :developer_documentation_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert developer_documentation_attestation == 'true',
               'Health IT developer did not demonstrate the documentation is available at a publicly accessible URL.'
        pass developer_documentation_notes if developer_documentation_notes.present?
      end
    end

    test do
      title 'Health IT developer confirms the Health IT Module does not cache the JWK Set received ' \
            'via a TLS-protected URL for longer than the cache-control header received by an application indicates.'
      description %(
        The Health IT developer confirms the Health IT Module does not cache the
        JWK Set received via a TLS-protected URL for longer than the
        cache-control header indicates.
      )
      id 'Test10'
      input :jwks_cache_attestation,
            title: 'Health IT developer confirms the Health IT Module does not cache the JWK Set received via a TLS-protected URL for longer than the cache-control header indicates.', # rubocop:disable Layout/LineLength
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
      input :jwks_cache_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert jwks_cache_attestation == 'true',
               'Health IT developer did not confirm that the JWK Sets are not cached for longer than appropriate.'
        pass jwks_cache_notes if jwks_cache_notes.present?
      end
    end

    test do
      title 'Health IT developer demonstrates support for the Patient Demographics Suffix USCDI v1 element.'
      description %(
        ONC certification criteria states that all USCDI v1 data classes and
        elements need to be supported, including Patient Demographics -
        Suffix.However, US Core v3.1.1 does not tag the relevant element
        (Patient.name.suffix) as MUST SUPPORT. The Health IT developer must
        demonstrate support for this USCDI v1 element as described in the US
        Core Patient Profile implementation guidance.
      )
      id 'Test11'

      required_suite_options G10Options::US_CORE_3_REQUIREMENT

      input :patient_suffix_attestation,
            title: 'Health IT developer demonstrates support for the Patient Demographics Suffix USCDI v1 element.',
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
      input :patient_suffix_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert patient_suffix_attestation == 'true',
               'Health IT developer did not demonstrate that Patient Demographics Suffix is supported.'
        pass patient_suffix_notes if patient_suffix_notes.present?
      end
    end

    test do
      title 'Health IT developer demonstrates support for issuing refresh tokens to native applications.'
      description %(
        The health IT developer demonstrates the ability of the Health IT Module
        to grant a refresh token valid for a period of no less than three months
        to native applications capable of storing a refresh token.

        This cannot be tested in an automated way because the health IT
        developer may require use of additional security mechanisms within the
        OAuth 2.0 authorization flow to ensure authorization is sufficiently
        secure for native applications.
      )
      id 'Test13'
      input :native_refresh_attestation,
            title: 'Health IT developer demonstrates support for issuing refresh tokens to native applications.',
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
      input :native_refresh_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert native_refresh_attestation == 'true',
               'Health IT developer did not demonstrate support for issuing refresh tokens to native applications.'
        pass native_refresh_notes if native_refresh_notes.present?
      end
    end

    test do
      title 'Health IT developer demonstrates the public location of its base URLs.'
      description %(
        To fulfill the API Maintenance of Certification requirement at §
        170.404(b)(2), the health IT developer demonstrates the public location
        of its certified API technology service base URLs.
      )
      id :g10_public_url_attestation
      input :public_url_attestation,
            title: 'Health IT developer demonstrates the public location of its certified API technology service base URLs', # rubocop:disable Layout/LineLength
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
      input :public_url_attestation_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert public_url_attestation == 'true',
               'Health IT developer did not demonstrate the public location of its certified API technology service base URLs.' # rubocop:disable Layout/LineLength
        pass public_url_attestation_notes if public_url_attestation_notes.present?
      end
    end

    test do
      title 'TLS version 1.2 or above must be enforced'
      description %(
        If TLS connections below version 1.2 have been allowed in any previous
        tests, Health IT developers must document how the Health IT Module
        enforces TLS version 1.2 or above.

        If no TLS connections below version 1.2 have been allowed, no
        documentation is necessary and this test will automatically pass.
      )
      id :g10_tls_version_attestation
      input :unique_incorrectly_permitted_tls_versions_messages,
            title: 'TLS Issues',
            type: 'textarea',
            locked: true,
            optional: true
      input :tls_documentation_required,
            title: 'Health IT developers must document how the Health IT Module enforces TLs version 1.2 or above.',
            type: 'radio',
            default: 'false',
            optional: true,
            locked: true,
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
      input :tls_version_attestation_notes,
            title: 'Document how TLS version 1.2 or above is enforced, if required:',
            type: 'textarea',
            optional: true

      run do
        if tls_documentation_required == 'true'
          assert tls_version_attestation_notes.present?,
                 'Health IT developer did not document how the system under test enforces TLS version 1.2 or above'
        end

        pass tls_version_attestation_notes if tls_version_attestation_notes.present?
      end
    end

    test do
      title 'Health IT developer attested that the Health IT Module is capable of issuing refresh tokens ' \
            'valid for a new period of no shorter than three months without requiring ' \
            're-authentication and re-authorization when a valid refresh token is supplied ' \
            'by the application.'
      description %(
        Applications that are capable of storing a client secret and that have
        received a refresh token must be able to use this refresh token to
        either receive a new refresh token valid for a new period of no less
        than three months, or to update the duration of the existing refresh
        token to be valid for a new period of no less than three months.  This
        occurs during the refresh token request, when the application uses a
        refresh token to receive a new access token.

        This attestation is necessary because automated tests cannot determine
        if the expiration date of the refresh token is updated when tokens
        are refreshed.

        This attestation ensures that the Health IT Module allows applications
        to use refresh tokens to update the length of authorized access beyond
        the initial period of no less than three months by issuing a new refresh
        token or updating the duration of the existing refresh token.  A
        separate attestation ensures that the Health IT Module is capable of
        issuing an initial refresh token that is valid for at least three
        months.
      )
      id :g10_refresh_token_refresh_attestation
      input :refresh_token_refresh_attestation,
            title: 'Health IT developer attested that the Health IT Module is capable of issuing refresh tokens ' \
                   'valid for a new period of no shorter than three months without requiring ' \
                   're-authentication and re-authorization when a valid refresh token is supplied ' \
                   'by the application.',
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
      input :refresh_token_refresh_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert refresh_token_refresh_attestation == 'true',
               'Health IT developer did not attest that the Health IT Module is capable of issuing refresh tokens ' \
               'valid for a new period of no shorter than three months without requiring ' \
               're-authentication and re-authorization when a valid refresh token is supplied ' \
               'by the application.'

        pass refresh_token_refresh_notes if refresh_token_refresh_notes.present?
      end
    end

    test do
      required_suite_options G10Options::BULK_DATA_2_REQUIREMENT
      title 'Health IT developer attested that the Health IT Module meets the ' \
            'requirements for supporting the `_since` parameter for bulk data exports.'
      description %(
        Resources will be included in the response if their state has changed
        after the supplied time (e.g., if `Resource.meta.lastUpdated` is later
        than the supplied `_since` time). In the case of a Group level export, the
        server MAY return additional resources modified prior to the supplied
        time if the resources belong to the patient compartment of a patient
        added to the Group after the supplied time (this behavior SHOULD be
        clearly documented by the server). For Patient- and Group-level
        requests, the server MAY return resources that are referenced by the
        resources being returned regardless of when the referenced resources
        were last updated. For resources where the server does not maintain a
        last updated time, the server MAY include these resources in a response
        irrespective of the _since value supplied by a client.
      )
      id :g10_bulk_v2_since_attestation
      input :bulk_v2_since_attestation,
            title: 'Health IT developer attested that the Health IT Module meets the ' \
                   'requirements for supporting the `_since` parameter for bulk data exports.',
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
      input :bulk_v2_since_attestation_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert bulk_v2_since_attestation == 'true',
               'Health IT developer did not attest that the Health IT Module meets the ' \
               'requirements for supporting the `_since` parameter for bulk data exports.'

        pass bulk_v2_since_attestation_notes if bulk_v2_since_attestation_notes.present?
      end
    end

    test do
      required_suite_options G10Options::SMART_2_REQUIREMENT.merge(G10Options::US_CORE_6_REQUIREMENT)
      title 'Health IT developer attested that the Health IT Module supports ' \
            'granting a sub resource scope for Clinical Test Observations.'

      description <<~DESCRIPTION
        As finalized in the HTI-1 Final Rule (89 FR 1294), Health IT Modules are
        required to support SMART App Launch v2.0.0 "Finer-grained resource
        constraints using search parameters" for the “category” parameter for
        the Condition resource with Condition sub-resources Encounter Diagnosis,
        Problem List, and Health Concern, and the Observation resource with
        Observation sub-resources Clinical Test, Laboratory, Social History,
        SDOH, Survey, and Vital Signs. We defer to the implementation guides
        referenced at § 170.215(b)(1) and § 170.215(c) for specific
        implementation guidance for this requirement. In the context of the US
        Core 6.1.0 implementation guide, the Observation sub-resources of
        Clinical Test and SDOH may have scopes supported as follows:

        * support for scopes for the Observation sub-resource Clinical Test
          using the "procedure" code from the US Core Clinical Result
          Observation Category value set.

        * support for scopes for the Observation sub-resource SDOH using the
          "sdoh" code from the US Core Category code system .
      DESCRIPTION
      id :g10_clinical_test_scope_attestation
      input :clinical_test_scope_attestation,
            title: 'Health IT developer attested that the Health IT Module supports ' \
                   'granting a sub resource scope for Clinical Test Observations.',
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
      input :clinical_test_scope_attestation_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert clinical_test_scope_attestation == 'true',
               'Health IT developer did not attest that the Health IT Module supports ' \
               'granting a sub resource scope for Clinical Test Observations.'

        pass clinical_test_scope_attestation_notes if clinical_test_scope_attestation_notes.present?
      end
    end

    test do
      required_suite_options G10Options::SMART_2_2_REQUIREMENT.merge(G10Options::US_CORE_6_REQUIREMENT)
      title 'Health IT developer attested that the Health IT Module supports ' \
            'granting a sub resource scope for Clinical Test Observations.'

      description <<~DESCRIPTION
        As finalized in the HTI-1 Final Rule (89 FR 1294), Health IT Modules are
        required to support SMART App Launch v2.0.0 "Finer-grained resource
        constraints using search parameters" for the “category” parameter for
        the Condition resource with Condition sub-resources Encounter Diagnosis,
        Problem List, and Health Concern, and the Observation resource with
        Observation sub-resources Clinical Test, Laboratory, Social History,
        SDOH, Survey, and Vital Signs. We defer to the implementation guides
        referenced at § 170.215(b)(1) and § 170.215(c) for specific
        implementation guidance for this requirement. In the context of the US
        Core 6.1.0 implementation guide, the Observation sub-resources of
        Clinical Test and SDOH may have scopes supported as follows:

        * support for scopes for the Observation sub-resource Clinical Test
          using the "procedure" code from the US Core Clinical Result
          Observation Category value set.

        * support for scopes for the Observation sub-resource SDOH using the
          "sdoh" code from the US Core Category code system .
      DESCRIPTION
      id :g10_clinical_test_scope_attestation_stu2_2
      input :clinical_test_scope_attestation,
            title: 'Health IT developer attested that the Health IT Module supports ' \
                   'granting a sub resource scope for Clinical Test Observations.',
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
      input :clinical_test_scope_attestation_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert clinical_test_scope_attestation == 'true',
               'Health IT developer did not attest that the Health IT Module supports ' \
               'granting a sub resource scope for Clinical Test Observations.'

        pass clinical_test_scope_attestation_notes if clinical_test_scope_attestation_notes.present?
      end
    end

    test do
      required_suite_options G10Options::SMART_2_REQUIREMENT.merge(G10Options::US_CORE_7_REQUIREMENT)
      title 'Health IT developer attested that the Health IT Module supports ' \
            'granting a sub resource scope for Clinical Test Observations.'

      description <<~DESCRIPTION
        As finalized in the HTI-1 Final Rule (89 FR 1294), Health IT Modules are
        required to support SMART App Launch v2.0.0 "Finer-grained resource
        constraints using search parameters" for the “category” parameter for
        the Condition resource with Condition sub-resources Encounter Diagnosis,
        Problem List, and Health Concern, and the Observation resource with
        Observation sub-resources Clinical Test, Laboratory, Social History,
        SDOH, Survey, and Vital Signs. We defer to the implementation guides
        referenced at § 170.215(b)(1) and § 170.215(c) for specific
        implementation guidance for this requirement. In the context of the US
        Core 6.1.0 implementation guide, the Observation sub-resources of
        Clinical Test and SDOH may have scopes supported as follows:

        * support for scopes for the Observation sub-resource Clinical Test
          using the "procedure" code from the US Core Clinical Result
          Observation Category value set.

        * support for scopes for the Observation sub-resource SDOH using the
          "sdoh" code from the US Core Category code system .
      DESCRIPTION
      id :g10_us_core_7_clinical_test_scope_attestation
      input :clinical_test_scope_attestation,
            title: 'Health IT developer attested that the Health IT Module supports ' \
                   'granting a sub resource scope for Clinical Test Observations.',
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
      input :clinical_test_scope_attestation_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert clinical_test_scope_attestation == 'true',
               'Health IT developer did not attest that the Health IT Module supports ' \
               'granting a sub resource scope for Clinical Test Observations.'

        pass clinical_test_scope_attestation_notes if clinical_test_scope_attestation_notes.present?
      end
    end

    test do
      required_suite_options G10Options::SMART_2_2_REQUIREMENT.merge(G10Options::US_CORE_7_REQUIREMENT)
      title 'Health IT developer attested that the Health IT Module supports ' \
            'granting a sub resource scope for Clinical Test Observations.'

      description <<~DESCRIPTION
        As finalized in the HTI-1 Final Rule (89 FR 1294), Health IT Modules are
        required to support SMART App Launch v2.0.0 "Finer-grained resource
        constraints using search parameters" for the “category” parameter for
        the Condition resource with Condition sub-resources Encounter Diagnosis,
        Problem List, and Health Concern, and the Observation resource with
        Observation sub-resources Clinical Test, Laboratory, Social History,
        SDOH, Survey, and Vital Signs. We defer to the implementation guides
        referenced at § 170.215(b)(1) and § 170.215(c) for specific
        implementation guidance for this requirement. In the context of the US
        Core 6.1.0 implementation guide, the Observation sub-resources of
        Clinical Test and SDOH may have scopes supported as follows:

        * support for scopes for the Observation sub-resource Clinical Test
          using the "procedure" code from the US Core Clinical Result
          Observation Category value set.

        * support for scopes for the Observation sub-resource SDOH using the
          "sdoh" code from the US Core Category code system .
      DESCRIPTION
      id :g10_us_core_7_clinical_test_scope_attestation_stu2_2
      input :clinical_test_scope_attestation,
            title: 'Health IT developer attested that the Health IT Module supports ' \
                   'granting a sub resource scope for Clinical Test Observations.',
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
      input :clinical_test_scope_attestation_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert clinical_test_scope_attestation == 'true',
               'Health IT developer did not attest that the Health IT Module supports ' \
               'granting a sub resource scope for Clinical Test Observations.'

        pass clinical_test_scope_attestation_notes if clinical_test_scope_attestation_notes.present?
      end
    end
  end
end
