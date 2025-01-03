module ONCCertificationG10TestKit
  class PatientContextTest < Inferno::Test
    title 'Patient from launch context can be retrieved'
    description %(
      The `patient` field is a String value with a patient id, indicating that
      the app was launched in the context of this FHIR Patient. This test
      verifies that the Patient resource with that id can be retrieved.
    )
    id :g10_patient_context
    input :patient_id, :url
    input :smart_auth_info, type: :auth_info

    fhir_client :authenticated do
      url :url
      auth_info :smart_auth_info
    end

    run do
      skip_if smart_auth_info.access_token.blank?, 'No access token was received during the SMART launch'

      skip_if patient_id.blank?, 'Token response did not contain `patient` field'

      skip_if request.status != 200, 'Token was not successfully refreshed' if config.options[:refresh_test]

      fhir_read(:patient, patient_id, client: :authenticated)

      assert_response_status(200)
      assert_resource_type(:patient)
    end
  end
end
