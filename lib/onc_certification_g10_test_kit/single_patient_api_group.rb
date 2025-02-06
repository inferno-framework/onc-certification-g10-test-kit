# TODO: remove this require with the next US Core test kit release
require 'us_core_test_kit/generator/special_cases'
require_relative 'incorrectly_permitted_tls_versions_messages_setup_test'

module ONCCertificationG10TestKit
  class SinglePatientAPIGroup < Inferno::TestGroup
    id :g10_single_patient_api
    title 'Single Patient API (US Core 3.1.1)'
    short_title 'Single Patient API'
    description %(
      This scenario verifies the ability of a system to provide a 'Single Patient API'
      as described in the (g)(10) Standardized API certification criterion.
      Prior to running this scenario, systems must recieve a verified access token
      from one of the previous SMART App Launch scenarios.

      For each of the relevant USCDI data elements provided in the
      CapabilityStatement, this scenario executes the [required supported
      searches](http://www.hl7.org/fhir/us/core/STU3.1.1/CapabilityStatement-us-core-server.html)
      as defined by the US Core Implementation Guide v3.1.1.

      The test begins by searching by one or more patients, with the expectation
      that the Bearer token provided to the test grants access to all USCDI
      resources. It uses results returned from that query to generate other
      queries and checks that the results are consistent with the provided
      search parameters. It then performs a read on each Resource returned and
      validates the response against the relevant
      [profile](http://www.hl7.org/fhir/us/core/STU3.1.1/profiles.html) as
      currently defined in the US Core Implementation Guide.

      All MUST SUPPORT elements must be seen before the test can pass, as well
      as Data Absent Reason to demonstrate that the server can properly handle
      missing data. Note that Encounter, Organization and Practitioner resources
      must be accessible as references in some US Core profiles to satisfy must
      support requirements, and those references will be validated to their US
      Core profile. These resources will not be tested for FHIR search support.
    )
    run_as_group

    input :url,
          title: 'FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by SMART applications'
    input :patient_id,
          title: 'Patient ID from SMART App Launch',
          locked: true
    input :additional_patient_ids,
          title: 'Additional Patient IDs',
          description: <<~DESCRIPTION,
            Comma separated list of Patient IDs that together with the Patient
            ID from the SMART App Launch contain all MUST SUPPORT elements.
          DESCRIPTION
          optional: true
    input :smart_credentials,
          title: 'SMART App Launch Credentials',
          type: :oauth_credentials,
          locked: true

    fhir_client do
      url :url
      oauth_credentials :smart_credentials
    end

    input_order :url, :patient_id, :additional_patient_ids, :implantable_device_codes, :smart_credentials

    config(
      options: {
        required_resources: [
          'Patient',
          'AllergyIntolerance',
          'CarePlan',
          'CareTeam',
          'Condition',
          'Device',
          'DiagnosticReport',
          'DocumentReference',
          'Goal',
          'Immunization',
          'MedicationRequest',
          'Observation',
          'Procedure',
          'Encounter',
          'Organization',
          'Practitioner',
          'Provenance'
        ]
      }
    )

    test do
      id :g10_patient_id_setup
      title 'Manage patient id list'

      input :patient_id, :additional_patient_ids
      output :patient_ids

      run do
        smart_app_launch_patient_id = patient_id.presence
        additional_patient_ids_list =
          if additional_patient_ids.present?
            additional_patient_ids
              .split(',')
              .map(&:strip)
              .map(&:presence)
              .compact
          else
            []
          end

        all_patient_ids = ([smart_app_launch_patient_id] + additional_patient_ids_list).compact.uniq

        output patient_ids: all_patient_ids.join(',')
      end
    end

    USCoreTestKit::USCoreV311::USCoreTestSuite
      .groups
      .find { |g| g.title == 'US Core FHIR API' }
      .groups
      .each do |group|
        test_group = group.ancestors[1]

        next if test_group.optional?

        group(from: test_group.id, exclude_optional: true)

        if test_group.respond_to?(:metadata) && # rubocop:disable Style/Next
           test_group.metadata.delayed? &&
           !test_group.metadata.searchable_delayed_resource?
          groups.last.children.reject! { |child| child.include? USCoreTestKit::SearchTest }
          groups.last.config(options: { read_all_resources: true })
        end
      end

    groups.first.description %(
      The Capability Statement test verifies a FHIR server's ability support the
      [capabilities
      operation](https://www.hl7.org/fhir/R4/capabilitystatement.html#instance)
      to formally describe features supported by the API as a [Capability
      Statement](https://www.hl7.org/fhir/R4/capabilitystatement.html) resource.
      The capabilities described in the Capability Statement must be consistent with
      the required capabilities of a US Core server.  This test also expects that
      APIs state support for all resources types applicable to USCDI v1, as is
      expected by the ONC (g)(10) Standardized API for Patient and Populations
      Services certification criterion.

      This test sequence accesses the server endpoint at `/metadata` using a
      `GET` request. It parses the Capability Statement and verifies that:

      * The endpoint is secured by an appropriate cryptographic protocol
      * The resource matches the expected FHIR version defined by the tests
      * The resource is a valid FHIR resource
      * The server claims support for JSON encoding of resources
      * The server claims support for all required USCDI resource types
    )

    test from: :g10_incorrectly_permitted_tls_versions_messages_setup
  end
end
