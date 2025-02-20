module ONCCertificationG10TestKit
  class EncounterContextTest < Inferno::Test
    title 'OAuth token exchange response body contains encounter context and encounter resource can be retrieved'
    description %(
      The `encounter` field is a String value with a encounter id, indicating that
      the app was launched in the context of this FHIR Encounter.
    )
    id :g10_encounter_context
    input :encounter_id, :url
    input :smart_auth_info, type: :auth_info

    fhir_client :authenticated do
      url :url
      auth_info :smart_auth_info
    end

    run do
      skip_if smart_auth_info.access_token.blank?, 'No access token was received during the SMART launch'

      skip_if encounter_id.blank?, 'Token response did not contain `encounter` field'

      skip_if request.status != 200, 'Token was not successfully refreshed' if config.options[:refresh_test]

      fhir_read(:encounter, encounter_id, client: :authenticated)

      assert_response_status(200)
      assert_resource_type(:encounter)
    end
  end
end
