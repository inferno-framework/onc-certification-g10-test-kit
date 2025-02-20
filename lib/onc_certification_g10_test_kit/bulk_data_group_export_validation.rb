require_relative 'bulk_export_validation_tester'

module ONCCertificationG10TestKit
  class BulkDataGroupExportValidation < Inferno::TestGroup
    title 'Group Compartment Export Validation Tests'
    short_description 'Verify that the exported data conforms to the US Core Implementation Guide.'
    description <<~DESCRIPTION
      Verify that Group compartment export from the Bulk Data server follow US Core Implementation Guide
    DESCRIPTION

    id :g10_bulk_data_group_export_validation

    input :status_output, :requires_access_token, :bulk_download_url
    input :bulk_smart_auth_info, type: :auth_info
    input :lines_to_validate,
          title: 'Limit validation to a maximum resource count',
          description: 'To validate all, leave blank.',
          optional: true
    input :bulk_patient_ids_in_group,
          title: 'Patient IDs in exported Group',
          description: <<~DESCRIPTION,
            Comma separated list of every Patient ID that is in the specified Group. This information is provided by
            the system under test to verify that data returned matches expectations. Leave blank to not verify Group
            inclusion.
          DESCRIPTION
          optional: true
    input :bulk_device_types_in_group,
          title: 'Implantable Device Type Codes in exported Group',
          description: <<~DESCRIPTION,
            Comma separated list of every Implantable Device type that is in the specified Group. This information is
            provided by the system under test to verify that data returned matches expectations. Leave blank to verify
            all Device resources against the Implantable Device profile.
          DESCRIPTION
          optional: true

    test from: :tls_version_test do
      title 'Bulk Data Server is secured by transport layer security'
      description <<~DESCRIPTION
        [§170.315(g)(10) Test Procedure]
        (https://www.healthit.gov/test-method/standardized-api-patient-and-population-services)
        requires that all exchanges described herein between a client and a
        server SHALL be secured using Transport Layer Security  (TLS)
        Protocol Version 1.2 (RFC5246).
      DESCRIPTION
      id :g10_bulk_file_server_tls_version

      config(
        inputs: { url: { name: :bulk_download_url } },
        options: { minimum_allowed_version: OpenSSL::SSL::TLS1_2_VERSION }
      )
    end

    test do
      title 'NDJSON download requires access token if requireAccessToken is true'
      description <<~DESCRIPTION
        If the requiresAccessToken field in the Complete Status body is set to true, the request SHALL include a valid#{' '}
        access token.

        [FHIR R4 Security](https://www.hl7.org/fhir/security.html#AccessDenied) and
        [The OAuth 2.0 Authorization Framework: Bearer Token Usage](https://tools.ietf.org/html/rfc6750#section-3.1)
        recommend using HTTP status code 401 for invalid token but also allow the actual result be controlled by policy#{' '}
        and context.
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/STU1.0.1/export/index.html#file-request'

      input :bulk_download_url, :requires_access_token
      input :bulk_smart_auth_info, type: :auth_info

      run do
        omit_if requires_access_token == 'false',
                'Could not verify this functionality when requiresAccessToken is false'

        skip_if bulk_smart_auth_info.access_token.blank?, 'No access token was received'

        get(bulk_download_url, headers: { accept: 'application/fhir+ndjson' })
        assert_response_status([400, 401])
      end
    end

    test do
      title 'Patient resources returned conform to the US Core Patient Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core Patient profile. This includes checking for missing data
        elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'

      include BulkExportValidationTester

      def resource_type
        'Patient'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Group export has at least two patients'
      description <<~DESCRIPTION
        This test verifies that the Group export has at least two patients.
      DESCRIPTION
      # link 'http://ndjson.org/'

      include BulkExportValidationTester

      run do
        skip 'No Patient resources processed from bulk data export.' unless patient_ids_seen.present?

        assert patient_ids_seen.length >= BulkExportValidationTester::MIN_RESOURCE_COUNT,
               'Bulk data export did not have multiple Patient resources.'
      end
    end

    test do
      title 'Patient IDs match those expected in Group'
      description <<~DESCRIPTION
        This test checks that the list of patient IDs that are expected match those that are returned.
        If no patient ids are provided to the test, then the test will be omitted.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'

      include BulkExportValidationTester

      run do
        omit 'No patient ids were given.' unless bulk_patient_ids_in_group.present?

        expected_ids = Set.new(bulk_patient_ids_in_group.split(',').map(&:strip))

        assert patient_ids_seen.sort == expected_ids.sort,
               "Mismatch between patient ids seen (#{patient_ids_seen.to_a.join(', ')}) " \
               "and patient ids expected (#{bulk_patient_ids_in_group})"
      end
    end

    test do
      title 'AllergyIntolerance resources returned conform to the US Core AllergyIntolerance Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core AllergyIntolerance profile. This includes
        checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance'

      include BulkExportValidationTester

      def resource_type
        'AllergyIntolerance'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'CarePlan resources returned conform to the US Core CarePlan Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core CarePlan profile. This includes checking for
        missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careplan'

      include BulkExportValidationTester

      def resource_type
        'CarePlan'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'CareTeam resources returned conform to the US Core CareTeam Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core CareTeam profile. This includes checking for missing data
        elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careteam'

      include BulkExportValidationTester

      def resource_type
        'CareTeam'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Condition resources returned conform to the relevant US Core Condition Profile'
      description <<~DESCRIPTION
        This test verifies that the server can provide evidence of support for
        the following US Core Condition profiles.  This includes checking for
        missing data elements and value set verification.

        For US Core v3.1.1 and v4.0.0 all resources must conform to the following profile:

        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition


        For US Core v6.1.0 and v7.0.0, evidence of support for the following two profiles must be demonstrated:

        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition-encounter-diagnosis
        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition-problems-health-concerns

      DESCRIPTION

      include BulkExportValidationTester

      def resource_type
        'Condition'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Device resources returned conform to the US Core Implantable Device Profile'
      description <<~DESCRIPTION
        This test verifies that relevant resources returned from bulk data export
        conform to the US Core Implantable Device profile. This includes
        checking for missing data elements and value set verification.

        Because not all Device resources on a system must conform to the Implantable Device
        profile, the tester may choose to provide a list of relevant Device Type Codes
        as an input to this test.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-implantable-device'

      include BulkExportValidationTester

      def resource_type
        'Device'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'DiagnosticReport resources returned conform to the relevant US Core DiagnosticReport Profile'
      description <<~DESCRIPTION
        This test verifies that the server can provide evidence of support for
        the following US Core DiagnosticReport profile based on the category of
        the DiagnosticReport. This includes checking for missing data elements
        and value set verification.

        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab
        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note
      DESCRIPTION

      include BulkExportValidationTester

      def resource_type
        'DiagnosticReport'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'DocumentReference resources returned conform to the US Core DocumentReference Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core DocumenReference profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-documentreference'

      include BulkExportValidationTester

      def resource_type
        'DocumentReference'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Goal resources returned conform to the US Core Goal Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core Goal profile. This includes checking for missing
        data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-goal'

      include BulkExportValidationTester

      def resource_type
        'Goal'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Immunization resources returned conform to the US Core Immunization Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core Immunization profile. This includes checking for
        missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-Immunization'

      include BulkExportValidationTester

      def resource_type
        'Immunization'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'MedicationRequest resources returned conform to the US Core MedicationRequest Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core MedicationRequest profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest'

      include BulkExportValidationTester

      def resource_type
        'MedicationRequest'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Observation resources returned conform to the relevant US Core Observation Profile'
      description <<~DESCRIPTION
          This test verifies that the resources returned from bulk data export
          conform to the following US Core profiles, based on the category or code
          associated with the Observation. This includes checking for missing data
          elements and value set verification.

          For US Core v3.1.1, this test expects evidence of the following US Core profiles

          * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age
          * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-weight-for-height
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus
          * http://hl7.org/fhir/us/core/StructureDefinition/head-occipital-frontal-circumference-percentile
          * http://hl7.org/fhir/StructureDefinition/bp
          * http://hl7.org/fhir/StructureDefinition/bodyheight
          * http://hl7.org/fhir/StructureDefinition/bodytemp
          * http://hl7.org/fhir/StructureDefinition/bodyweight
          * http://hl7.org/fhir/StructureDefinition/heartrate
          * http://hl7.org/fhir/StructureDefinition/resprate

          For US Core v4.0.0, this test expects evidence of the following US Core profiles

          * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age
          * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-weight-for-height
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus
          * http://hl7.org/fhir/us/core/StructureDefinition/head-occipital-frontal-circumference-percentile
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-blood-pressure
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-bmi
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-head-circumference
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-body-height
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-body-weight
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-body-temperature
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-heart-rate
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-respiratory-rate

          For US Core v6.1.0, this test expects evidence of the following US Core profiles
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-occupation
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-pregnancyintent
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-pregnancystatus
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-screening-assessment
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-sexual-orientation
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus
          * http://hl7.org/fhir/us/core/StructureDefinition/head-occipital-frontal-circumference-percentile
          * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age
          * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-weight-for-height
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-blood-pressure
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-bmi
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-body-height
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-body-temperature
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-body-weight
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-head-circumference
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-heart-rate
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-respiratory-rate

        For US Core v7.0.0, this test expects evidence of the following US Core profiles
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-occupation
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-pregnancyintent
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-pregnancystatus
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-screening-assessment
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-sexual-orientation
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus
          * http://hl7.org/fhir/us/core/StructureDefinition/head-occipital-frontal-circumference-percentile
          * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age
          * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-weight-for-height
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-blood-pressure
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-bmi
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-body-height
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-body-temperature
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-body-weight
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-head-circumference
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-heart-rate
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-respiratory-rate
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-treatment-intervention-preference
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-care-experience-preference
          * http://hl7.org/fhir/us/core/StructureDefinition/us-core-average-blood-pressure
      DESCRIPTION

      include BulkExportValidationTester

      def resource_type
        'Observation'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Procedure resources returned conform to the US Core Procedure Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core Procedure profile. This includes checking for
        missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-procedure'

      include BulkExportValidationTester

      def resource_type
        'Procedure'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Encounter resources returned conform to the US Core Encounter Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core Encounter profile. This includes checking for
        missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter'

      include BulkExportValidationTester

      def resource_type
        'Encounter'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Organization resources returned conform to the US Core Organization Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core Organization profile. This includes checking for
        missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization'

      include BulkExportValidationTester

      def resource_type
        'Organization'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Practitioner resources returned conform to the US Core Practitioner Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core Practioner profile. This includes checking for
        missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner'

      include BulkExportValidationTester

      def resource_type
        'Practitioner'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Provenance resources returned conform to the US Core Provenance Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core profiles. This includes checking for missing data
        elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance'

      include BulkExportValidationTester

      def resource_type
        'Provenance'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Location resources returned conform to the HL7 FHIR Specification Location Resource if bulk data export ' \
            'has Location resources'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the HL7 FHIR Specification Location Resource. This includes
        checking for missing data elements and value set verification. This test
        is omitted if bulk data export does not return any Location resources.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-location'

      required_suite_options G10Options::US_CORE_3_REQUIREMENT

      id :g10_us_core_3_bulk_location_validation

      include BulkExportValidationTester

      def resource_type
        'Location'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Location resources returned conform to the HL7 FHIR Specification Location Resource if bulk data export ' \
            'has Location resources'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the HL7 FHIR Specification Location Resource. This includes
        checking for missing data elements and value set verification. This test
        is omitted if bulk data export does not return any Location resources.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-location'

      required_suite_options G10Options::US_CORE_4_REQUIREMENT

      id :g10_us_core_4_bulk_location_validation

      include BulkExportValidationTester

      def resource_type
        'Location'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Location resources returned conform to the HL7 FHIR Specification Location Resource if bulk data export ' \
            'has Location resources'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the HL7 FHIR Specification Location Resource. This includes
        checking for missing data elements and value set verification. This test
        is omitted if bulk data export does not return any Location resources.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-location'

      required_suite_options G10Options::US_CORE_5_REQUIREMENT

      id :g10_us_core_5_bulk_location_validation

      include BulkExportValidationTester

      def resource_type
        'Location'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Location resources returned conform to the HL7 FHIR Specification Location Resource if bulk data export ' \
            'has Location resources'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the HL7 FHIR Specification Location Resource. This includes
        checking for missing data elements and value set verification. This test
        is omitted if bulk data export does not return any Location resources.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-location'

      required_suite_options G10Options::US_CORE_6_REQUIREMENT

      id :g10_us_core_6_bulk_location_validation

      include BulkExportValidationTester

      def resource_type
        'Location'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Medication resources returned conform to the US Core Medication Profile if bulk data export has ' \
            'Medication resources'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core Medication profile, if available. This includes
        checking for missing data elements and value set verification. This test
        is omitted if bulk data export does not return any Medication resources.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication'

      include BulkExportValidationTester

      def resource_type
        'Medication'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'ServiceRequest resources returned conform to the US Core ServiceRequest Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core ServiceRequest profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_5_REQUIREMENT

      id :g10_us_core_5_bulk_service_request_validation

      include BulkExportValidationTester

      def resource_type
        'ServiceRequest'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'RelatedPerson resources returned conform to the US Core RelatedPerson Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core RelatedPerson profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_5_REQUIREMENT

      id :g10_us_core_5_bulk_related_person_validation

      include BulkExportValidationTester

      def resource_type
        'RelatedPerson'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'QuestionnaireResponse resources returned conform to the US Core QuestionnaireResponse Profile if ' \
            'bulk data has QuestionnaireResponse resources'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core QuestionnaireResponse profile. This includes checking for missing
        data elements and value set verification. This test is omitted if bulk
        data export does not return any QuestionnaireResponse resources.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_5_REQUIREMENT

      id :g10_us_core_5_bulk_questionnaire_response_validation

      include BulkExportValidationTester

      def resource_type
        'QuestionnaireResponse'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'PractionerRole resources returned conform to the US Core PractionerRole Profile if bulk data export ' \
            'has PractionerRole resources'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core PractitionerRole profile. This includes checking for missing
        data elements and value set verification. This test is omitted if bulk
        data export does not return any  resources.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_5_REQUIREMENT

      id :g10_us_core_5_bulk_practitioner_role_validation

      include BulkExportValidationTester

      def resource_type
        'PractitionerRole'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'ServiceRequest resources returned conform to the US Core ServiceRequest Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core ServiceRequest profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION

      id :g10_us_core_6_bulk_service_request_validation

      required_suite_options G10Options::US_CORE_6_REQUIREMENT

      include BulkExportValidationTester

      def resource_type
        'ServiceRequest'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'RelatedPerson resources returned conform to the US Core RelatedPerson Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core RelatedPerson profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_6_REQUIREMENT

      id :g10_us_core_6_bulk_related_person_validation

      include BulkExportValidationTester

      def resource_type
        'RelatedPerson'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'QuestionnaireResponse resources returned conform to the US Core QuestionnaireResponse Profile if ' \
            'bulk data has QuestionnaireResponse resources'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core QuestionnaireResponse profile. This includes checking for missing
        data elements and value set verification. This test is omitted if bulk
        data export does not return any QuestionnaireResponse resources.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_6_REQUIREMENT

      id :g10_us_core_6_bulk_questionnaire_response_validation

      include BulkExportValidationTester

      def resource_type
        'QuestionnaireResponse'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'PractionerRole resources returned conform to the US Core PractionerRole Profile if bulk data export ' \
            'has PractionerRole resources'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core PractitionerRole profile. This includes checking for missing
        data elements and value set verification. This test is omitted if bulk
        data export does not return any  resources.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_6_REQUIREMENT

      id :g10_us_core_6_bulk_practitioner_role_validation

      include BulkExportValidationTester

      def resource_type
        'PractitionerRole'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Coverage resources returned conform to the US Core Coverage Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core Coverage profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_6_REQUIREMENT

      id :g10_us_core_6_bulk_coverage_validation

      include BulkExportValidationTester

      def resource_type
        'Coverage'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'MedicationDispense resources returned conform to the US Core MedicationDispense Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core MedicationDispense profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_6_REQUIREMENT

      id :g10_us_core_6_bulk_medication_dispense_validation

      include BulkExportValidationTester

      def resource_type
        'MedicationDispense'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Specimen resources returned conform to the US Core Specimen Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core Specimen profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_6_REQUIREMENT

      id :g10_us_core_6_bulk_specimen_validation

      include BulkExportValidationTester

      def resource_type
        'Specimen'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'ServiceRequest resources returned conform to the US Core ServiceRequest Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core ServiceRequest profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION

      id :g10_us_core_7_bulk_service_request_validation

      required_suite_options G10Options::US_CORE_7_REQUIREMENT

      include BulkExportValidationTester

      def resource_type
        'ServiceRequest'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'RelatedPerson resources returned conform to the US Core RelatedPerson Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core RelatedPerson profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_7_REQUIREMENT

      id :g10_us_core_7_bulk_related_person_validation

      include BulkExportValidationTester

      def resource_type
        'RelatedPerson'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'QuestionnaireResponse resources returned conform to the US Core QuestionnaireResponse Profile if ' \
            'bulk data has QuestionnaireResponse resources'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core QuestionnaireResponse profile. This includes checking for missing
        data elements and value set verification. This test is omitted if bulk
        data export does not return any QuestionnaireResponse resources.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_7_REQUIREMENT

      id :g10_us_core_7_bulk_questionnaire_response_validation

      include BulkExportValidationTester

      def resource_type
        'QuestionnaireResponse'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'PractionerRole resources returned conform to the US Core PractionerRole Profile if bulk data export ' \
            'has PractionerRole resources'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core PractitionerRole profile. This includes checking for missing
        data elements and value set verification. This test is omitted if bulk
        data export does not return any  resources.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_7_REQUIREMENT

      id :g10_us_core_7_bulk_practitioner_role_validation

      include BulkExportValidationTester

      def resource_type
        'PractitionerRole'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Coverage resources returned conform to the US Core Coverage Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core Coverage profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_7_REQUIREMENT

      id :g10_us_core_7_bulk_coverage_validation

      include BulkExportValidationTester

      def resource_type
        'Coverage'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'MedicationDispense resources returned conform to the US Core MedicationDispense Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core MedicationDispense profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_7_REQUIREMENT

      id :g10_us_core_7_bulk_medication_dispense_validation

      include BulkExportValidationTester

      def resource_type
        'MedicationDispense'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Specimen resources returned conform to the US Core Specimen Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core Specimen profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_7_REQUIREMENT

      id :g10_us_core_7_bulk_specimen_validation

      include BulkExportValidationTester

      def resource_type
        'Specimen'
      end

      run do
        perform_bulk_export_validation
      end
    end

    test do
      title 'Location resources returned conform to the US Core Location Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export
        conform to the US Core Location profile. This includes checking
        for missing data elements and value set verification.
      DESCRIPTION

      required_suite_options G10Options::US_CORE_7_REQUIREMENT

      id :g10_us_core_7_bulk_location_validation

      include BulkExportValidationTester

      def resource_type
        'Location'
      end

      run do
        perform_bulk_export_validation
      end
    end
  end
end
