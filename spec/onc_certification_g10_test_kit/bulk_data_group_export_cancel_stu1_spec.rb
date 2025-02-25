require_relative '../../lib/onc_certification_g10_test_kit/bulk_data_group_export_cancel_stu1'

RSpec.describe ONCCertificationG10TestKit::BulkDataGroupExportCancelSTU1 do
  let(:group) { Inferno::Repositories::TestGroups.new.find('g10_bulk_data_export_cancel_stu1') }
  let(:suite_id) { 'g10_certification' }
  let(:bulk_server_url) { 'https://example.com/fhir' }
  let(:bearer_token) { 'some_bearer_token_alphanumeric' }
  let(:group_id) { '1219' }
  let(:polling_url) { 'https://redirect.com' }
  let(:bulk_smart_auth_info) { Inferno::DSL::AuthInfo.new(access_token: bearer_token) }
  let(:base_input) do
    {
      bulk_server_url:,
      bulk_smart_auth_info:,
      group_id:
    }
  end

  describe 'delete request tests' do
    let(:runnable) { group.tests[0] }
    let(:bulk_export_url) { "#{bulk_server_url}/Group/1219/$export" }

    it 'skips when no Bearer Token is given' do
      base_input[:bulk_smart_auth_info].access_token = nil
      result = run(runnable, base_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not verify this functionality when bearer token is not set')
    end

    it 'fails when unable to kick-off export' do
      stub_request(:get, bulk_export_url)
        .to_return(status: 404)

      result = run(runnable, base_input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Unexpected response status: expected 202, but received 404')
    end

    it 'fails when content-location header not provided in kick-off response' do
      stub_request(:get, bulk_export_url)
        .to_return(status: 202)

      result = run(runnable, base_input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Export response header did not include "Content-Location"')
    end

    it 'fails when content-location header has no value' do
      stub_request(:get, bulk_export_url)
        .to_return(status: 202, headers: { 'content-type': nil })

      result = run(runnable, base_input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Export response header did not include "Content-Location"')
    end

    it 'fails when response to delete request is not 202' do
      stub_request(:get, bulk_export_url)
        .to_return(status: 202, headers: { 'content-location': polling_url })
      stub_request(:delete, polling_url)
        .with(headers: { authorization: "Bearer #{bearer_token}" })
        .to_return(status: 404)

      result = run(runnable, base_input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Unexpected response status: expected 202, but received 404')
    end

    it 'passes when delete request includes bearer token and response is 202' do
      stub_request(:get, bulk_export_url)
        .to_return(status: 202, headers: { 'content-location': polling_url })
      stub_request(:delete, polling_url)
        .with(headers: { authorization: "Bearer #{bearer_token}" })
        .to_return(status: 202)

      result = run(runnable, base_input)

      expect(result.result).to eq('pass')
    end
  end
end
