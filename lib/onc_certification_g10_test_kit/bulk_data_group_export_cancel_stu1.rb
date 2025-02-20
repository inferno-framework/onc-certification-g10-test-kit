require_relative 'export_kick_off_performer'

module ONCCertificationG10TestKit
  class BulkDataGroupExportCancelSTU1 < Inferno::TestGroup
    id :g10_bulk_data_export_cancel_stu1
    title 'Group Compartment Export Cancel Tests'
    description %(
      Verify that the Bulk Data server supports cancelling requested exports.
      This group initiates a new export and immediately cancels it to verify
      correct behavior.
    )

    input :bulk_smart_auth_info, type: :auth_info
    input :bulk_server_url,
          title: 'Bulk Data FHIR URL',
          description: 'The URL of the Bulk FHIR server.'
    input :group_id,
          title: 'Group ID',
          description: 'The Group ID associated with the group of patients to be exported.'

    http_client :bulk_server do
      url :bulk_server_url
    end

    test do
      id :g10_bulk_export_cancel
      title 'Bulk Data Server returns "202 Accepted" for delete request'
      description <<~DESCRIPTION
        After a bulk data request has been started, a client MAY send a delete request to the URL provided in the Content-Location header to cancel the request.
        Bulk Data Server MUST support client's delete request and return HTTP Status Code of "202 Accepted"
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/STU1.0.1/export/index.html#bulk-data-delete-request'

      include ExportKickOffPerformer

      output :cancelled_polling_url

      run do
        perform_export_kick_off_request
        assert_response_status(202)

        output cancelled_polling_url: request.response_header('content-location')&.value

        delete_export_kick_off_request
      end
    end
  end
end
