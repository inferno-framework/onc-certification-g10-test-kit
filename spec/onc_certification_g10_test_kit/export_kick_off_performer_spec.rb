require_relative '../../lib/onc_certification_g10_test_kit/export_kick_off_performer'

class ExportKickOffPerformerTesterClass < Inferno::Test
  include ONCCertificationG10TestKit::ExportKickOffPerformer
  attr_accessor :bulk_smart_auth_info, :group_id, :requests

  def http_clients
    { bulk_server: Inferno::DSL::HTTPClientBuilder.new.build(self, proc { url 'https://www.example.com' }) }
  end
end

RSpec.describe ONCCertificationG10TestKit::ExportKickOffPerformer do
  let(:token) { 'some_token' }
  let(:group_id) { 'some_group_id' }
  let(:bulk_server_url) { 'https://www.example.com' }
  let(:polling_url) { 'https://www.some_polling_url.com' }
  let(:performer) { ExportKickOffPerformerTesterClass.new }
  let(:request) { Inferno::Entities::Request.new({ headers: [header] }) }
  let(:bulk_export_url) { "#{bulk_server_url}/Group/#{group_id}/$export" }
  let(:params) { { _outputFormat: 'application/fhir+ndjson', _sort: 'sample+value' } }
  let(:bulk_smart_auth_info) do
    Inferno::DSL::AuthInfo.new(access_token: token)
  end
  let(:header) do
    Inferno::Entities::Header.new(
      name: 'content-location',
      type: 'response',
      value: polling_url
    )
  end

  before do
    performer.bulk_smart_auth_info = bulk_smart_auth_info
    performer.group_id = group_id
    performer.requests = [request]
  end

  describe 'perform_export_kick_off_request' do
    let(:no_token_header_req) do
      stub_request(:get, bulk_export_url)
        .to_return(status: 200)
    end

    let(:token_header_req) do
      stub_request(:get, bulk_export_url)
        .with(headers: { 'authorization' => "Bearer #{token}" })
        .to_return(status: 200)
    end

    it 'raises skip if use_token but token is not present' do
      performer.bulk_smart_auth_info.access_token = nil

      expect { performer.perform_export_kick_off_request }
        .to raise_exception(Inferno::Exceptions::SkipException)
        .with_message('Could not verify this functionality when bearer token is not set')
    end

    it 'excludes token from request header if !use_token' do
      no_token_header_req
      performer.perform_export_kick_off_request(use_token: false)

      expect(no_token_header_req).to have_been_made.once
      expect(token_header_req).to have_not_been_made
    end

    it 'includes token in request header if use_token' do
      token_header_req
      performer.perform_export_kick_off_request

      expect(token_header_req).to have_been_made.once
    end

    it 'includes single param in request url if param' do
      params_url_req = stub_request(:get, "#{bulk_export_url}?_outputFormat=application%2Ffhir%2Bndjson")
        .with(headers: { 'authorization' => "Bearer #{token}" })
        .to_return(status: 200)

      performer.perform_export_kick_off_request(params: { _outputFormat: 'application/fhir+ndjson' })
      expect(params_url_req).to have_been_made.once
    end

    it 'includes multiple params in request url if params' do
      params_url_req = stub_request(:get,
                                    "#{bulk_export_url}?_outputFormat=application%2Ffhir%2Bndjson&_sort=sample%2Bvalue")
        .with(headers: { 'authorization' => "Bearer #{token}" })
        .to_return(status: 200)

      performer.perform_export_kick_off_request(params:)
      expect(params_url_req).to have_been_made.once
    end

    it "makes the named request 'export'" do
      token_header_req
      performer.perform_export_kick_off_request

      expect(performer.requests.last.name).to be(:export)
    end
  end

  describe 'delete_export_kick_off_request' do
    let(:token_header_delete) do
      stub_request(:delete, polling_url)
        .with(headers: { 'authorization' => "Bearer #{token}" })
        .to_return(status: 202)
    end

    it 'raises exception if no request/response' do
      performer.requests = []

      expect { performer.delete_export_kick_off_request }
        .to raise_exception(Inferno::Exceptions::AssertionException)
        .with_message('Export response header did not include "Content-Location"')
    end

    it "raises exception if no 'content-location' header in response" do
      performer.request.headers = []

      expect { performer.delete_export_kick_off_request }
        .to raise_exception(Inferno::Exceptions::AssertionException)
        .with_message('Export response header did not include "Content-Location"')
    end

    it 'fails if no value for content-location header in response' do
      performer.request.headers.first.value = nil

      expect { performer.delete_export_kick_off_request }
        .to raise_exception(Inferno::Exceptions::AssertionException)
        .with_message('Export response header did not include "Content-Location"')
    end

    it 'includes token in delete request header' do
      token_header_delete
      performer.delete_export_kick_off_request

      expect(token_header_delete).to have_been_made.once
    end

    it 'raises exception if delete request unsuccessful' do
      stub_request(:delete, polling_url)
        .with(headers: { 'authorization' => "Bearer #{token}" })
        .to_return(status: 404)

      expect { performer.delete_export_kick_off_request }
        .to raise_exception(Inferno::Exceptions::AssertionException)
        .with_message('Unexpected response status: expected 202, but received 404')
    end

    it 'returns nil if delete request successful' do
      token_header_delete

      expect(performer.delete_export_kick_off_request).to be_nil
    end
  end
end
