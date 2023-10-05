require_relative 'bulk_data_authorization'
require_relative 'bulk_data_group_export_stu1'
require_relative 'bulk_data_group_export_cancel_stu1'
require_relative 'bulk_data_group_export_validation'
require_relative 'incorrectly_permitted_tls_versions_messages_setup_test'

module ONCCertificationG10TestKit
  class MultiPatientAPIGroupSTU1 < Inferno::TestGroup
    title 'Multi-Patient Authorization and API'
    short_title 'Multi-Patient API'

    input_instructions %(
      Register Inferno as a bulk data client with the following information, and
      enter the client id and client registration in the appropriate fields.
      This set of tests only checks the Group export. Enter the group export
      information in the appropriate box.

      Register Inferno with the following JWK Set Url:

      * `#{Inferno::Application[:base_url]}/custom/g10_certification/.well-known/jwks.json`
    )

    # TODO: update this description based on US Core 6 update
    description %(
      Demonstrate the ability to export clinical data for multiple patients in
      a group using [FHIR Bulk Data Access
      IG](http://hl7.org/fhir/uv/bulkdata/STU1.0.1/). This test uses [Backend Services
      Authorization](http://hl7.org/fhir/uv/bulkdata/STU1.0.1/authorization/index.html)
      to obtain an access token from the server. After authorization, a group
      level bulk data export request is initialized. Finally, this test reads
      exported NDJSON files from the server and validates the resources in
      each file. To run the test successfully, the selected group export is
      required to have every type of resource mapped to [USCDI data
      elements](https://www.healthit.gov/isa/us-core-data-interoperability-uscdi).
      Additionally, it is expected the server will provide Encounter,
      Location, Organization, and Practitioner resources as they are
      referenced as must support elements in required resources.
    )
    id :multi_patient_api
    run_as_group

    input_order :bulk_server_url,
                :bulk_token_endpoint,
                :bulk_client_id,
                :bulk_scope,
                :bulk_encryption_method,
                :group_id,
                :bulk_patient_ids_in_group,
                :bulk_device_types_in_group,
                :lines_to_validate,
                :bulk_timeout

    group from: :bulk_data_authorization,
          description: <<~DESCRIPTION
            Bulk Data servers are required to authorize clients using the [Backend Service
            Authorization](http://hl7.org/fhir/uv/bulkdata/STU1.0.1/authorization/index.html)
            specification as defined in the [FHIR Bulk Data Access IG
            v1.0.1](http://hl7.org/fhir/uv/bulkdata/STU1.0.1/).

            In this set of tests, Inferno serves as a Bulk Data client that requests authorization
            from the Bulk Data authorization server.  It also performs a number of negative tests
            to validate that the authorization service does not improperly authorize invalid
            requests.

            This test returns an access token.
          DESCRIPTION

    test from: :g10_incorrectly_permitted_tls_versions_messages_setup,
         id: :g10_bulk_auth_tls_messages_setup

    group from: :bulk_data_group_export

    test from: :g10_incorrectly_permitted_tls_versions_messages_setup,
         id: :g10_bulk_group_export_tls_messages_setup

    group from: :bulk_data_group_export_validation

    test from: :g10_incorrectly_permitted_tls_versions_messages_setup,
         id: :g10_bulk_group_export_validation_messages_setup

    group from: :g10_bulk_data_export_cancel_stu1
  end
end
