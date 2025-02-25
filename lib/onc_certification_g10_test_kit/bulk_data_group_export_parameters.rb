require_relative 'export_kick_off_performer'

module ONCCertificationG10TestKit
  class BulkDataGroupExportParameters < Inferno::TestGroup
    id :g10_bulk_data_export_parameters
    title 'Group Compartment Export Parameters Tests'
    description %(
      Verify that the Bulk Data server supports required query parameters.
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
      title 'Bulk Data Server supports "_outputFormat" query parameter'
      description <<~DESCRIPTION
        [_outputFormat](http://hl7.org/fhir/uv/bulkdata/STU2/export.html#query-parameters):
        The format for the requested Bulk Data files to be
        generated as per FHIR Asynchronous Request Pattern. Defaults to
        application/fhir+ndjson. The server SHALL support Newline Delimited
        JSON, but MAY choose to support additional output formats. The server
        SHALL accept the full content type of application/fhir+ndjson as well
        as the abbreviated representations application/ndjson and ndjson.
      DESCRIPTION

      id :output_format_in_export_response

      include ExportKickOffPerformer

      run do
        ['application/fhir+ndjson', 'application/ndjson', 'ndjson'].each do |format|
          perform_export_kick_off_request(params: { _outputFormat: format })
          assert_response_status(202)

          delete_export_kick_off_request
        end
      end
    end

    test do
      title 'Bulk Data Server supports "_since" query parameter'
      description <<~DESCRIPTION
        This test verifies that the server accepts an export request with the
        `[_since](http://hl7.org/fhir/uv/bulkdata/STU2/export.html#query-parameters)`
        query parameter.  It initiates a new export using a _since parameter of
        one week ago, and ensures that the export was initiated succesfully.

        The test does not attempt to verify that resources returned were
        modified after the _since date that was requested, because the Bulk Data
        specification provides latitude in determining exactly what data is
        returned by the server.  The purpose of this test is to ensure that
        export requests with this parameter are accepted and to highlight that
        support of this parameter is required.

        After the export was successfully initiated, it is then cancelled.
      DESCRIPTION

      id :g10_since_in_export_response

      include ExportKickOffPerformer

      input :since_timestamp,
            title: 'Timestamp for _since parameter',
            description: 'A timestamp formatted as a FHIR instant which will be used to test the ' \
                         "server's support for the `_since` query parameter",
            default: 1.week.ago.iso8601

      run do
        fhir_instant_regex = /
          ([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)
          -(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])
          T([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\.[0-9]+)
          ?(Z|(\+|-)((0[0-9]|1[0-3]):[0-5][0-9]|14:00))
        /x

        assert since_timestamp.match?(fhir_instant_regex),
               "The provided `_since` timestamp `#{since_timestamp}` is not a valid " \
               '[FHIR instant](https://www.hl7.org/fhir/datatypes.html#instant).'

        perform_export_kick_off_request(params: { _since: since_timestamp })
        assert_response_status(202)

        delete_export_kick_off_request
      end
    end
  end
end
