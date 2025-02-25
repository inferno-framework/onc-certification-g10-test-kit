require_relative 'bulk_data_group_export_cancel_stu1'

module ONCCertificationG10TestKit
  class BulkDataGroupExportCancelSTU2 < BulkDataGroupExportCancelSTU1
    id :g10_bulk_data_export_cancel_stu2

    test do
      title 'Bulk Data Server returns a 404 and OperationOutcome for polling requests to cancelled exports'
      description <<~DESCRIPTION
        > Following the delete request, when subsequent requests are made to the
          polling location, the server SHALL return a 404 Not Found error and an
          associated FHIR OperationOutcome in JSON format.

        http://hl7.org/fhir/uv/bulkdata/STU2/export.html#bulk-data-delete-request
      DESCRIPTION

      id :bulk_data_poll_cancelled_export

      input :cancelled_polling_url

      run do
        skip 'No polling url available' unless cancelled_polling_url.present?

        get(
          cancelled_polling_url,
          headers: {
            authorization: "Bearer #{bulk_smart_auth_info.access_token}",
            accept: 'application/json'
          }
        )

        assert_response_status(404)

        assert_valid_json(response[:body])
        response_body = JSON.parse(response[:body])

        assert response_body['resourceType'] == 'OperationOutcome', 'Server did not return an OperationOutcome'
        assert_valid_resource(resource: FHIR::OperationOutcome.new(response_body))
      end
    end
  end
end
