require_relative '../../lib/onc_certification_g10_test_kit/smart_standalone_patient_app_group'

RSpec.describe ONCCertificationG10TestKit::SmartStandalonePatientAppGroup do
  it 'has a properly configured SMART v1 auth input' do
    inputs =
      described_class.available_inputs(
        [Inferno::DSL::SuiteOption.new(id: :smart_app_launch_version, value: 'smart_app_launch_1')]
      )

    auth_input = inputs[:standalone_smart_auth_info]

    expected_auth_input_options =
      {
        mode: 'auth',
        components: [
          {
            name: :auth_type,
            default: 'symmetric',
            options: {
              list_options: [
                { label: 'Public', value: 'public' },
                { label: 'Confidential Symmetric', value: 'symmetric' }
              ]
            },
            locked: true
          },
          {
            name: :requested_scopes,
            type: 'textarea',
            default: 'launch/patient openid fhirUser offline_access patient/Medication.read patient/AllergyIntolerance.read patient/CarePlan.read patient/CareTeam.read patient/Condition.read patient/Device.read patient/DiagnosticReport.read patient/DocumentReference.read patient/Encounter.read patient/Goal.read patient/Immunization.read patient/Location.read patient/MedicationRequest.read patient/Observation.read patient/Organization.read patient/Patient.read patient/Practitioner.read patient/Procedure.read patient/Provenance.read patient/PractitionerRole.read'
          },
          { name: :auth_request_method, default: 'GET', locked: true },
          { name: :use_discovery, locked: true }
        ]
      }

    expect(auth_input.options[:components]).to match_array(expected_auth_input_options[:components])
  end

  it 'has a properly configured SMART v2 auth input' do
    inputs =
      described_class.available_inputs(
        [Inferno::DSL::SuiteOption.new(id: :smart_app_launch_version, value: 'smart_app_launch_2')]
      )

    auth_input = inputs[:standalone_smart_auth_info]

    expected_auth_input_options =
      {
        mode: 'auth',
        components: [
          {
            name: :auth_type,
            default: 'symmetric',
            options: {
              list_options: [
                { label: 'Public', value: 'public' },
                { label: 'Confidential Symmetric', value: 'symmetric' },
                { label: 'Confidential Asymmetric', value: 'asymmetric' },
                { label: 'Backend Services', value: 'backend_services' }
              ]
            },
            locked: true
          },
          {
            name: :requested_scopes,
            type: 'textarea',
            default: 'launch/patient openid fhirUser offline_access patient/Medication.rs patient/AllergyIntolerance.rs patient/CarePlan.rs patient/CareTeam.rs patient/Condition.rs patient/Device.rs patient/DiagnosticReport.rs patient/DocumentReference.rs patient/Encounter.rs patient/Goal.rs patient/Immunization.rs patient/Location.rs patient/MedicationRequest.rs patient/Observation.rs patient/Organization.rs patient/Patient.rs patient/Practitioner.rs patient/Procedure.rs patient/Provenance.rs patient/PractitionerRole.rs'
          },
          { name: :auth_request_method, default: 'GET', locked: true },
          { name: :use_discovery, locked: true },
          { name: :pkce_support, default: 'enabled', locked: true },
          { name: :pkce_code_challenge_method, default: 'S256', locked: true }
        ]
      }

    expect(auth_input.options[:components]).to match_array(expected_auth_input_options[:components])
  end

  it 'has a properly configured SMART v2.2 auth input' do
    inputs =
      described_class.available_inputs(
        [Inferno::DSL::SuiteOption.new(id: :smart_app_launch_version, value: 'smart_app_launch_2_2')]
      )

    auth_input = inputs[:standalone_smart_auth_info]

    expected_auth_input_options =
      {
        mode: 'auth',
        components: [
          {
            name: :auth_type,
            default: 'symmetric',
            options: {
              list_options: [
                { label: 'Public', value: 'public' },
                { label: 'Confidential Symmetric', value: 'symmetric' },
                { label: 'Confidential Asymmetric', value: 'asymmetric' },
                { label: 'Backend Services', value: 'backend_services' }
              ]
            },
            locked: true
          },
          {
            name: :requested_scopes,
            type: 'textarea',
            default: 'launch/patient openid fhirUser offline_access patient/Medication.rs patient/AllergyIntolerance.rs patient/CarePlan.rs patient/CareTeam.rs patient/Condition.rs patient/Device.rs patient/DiagnosticReport.rs patient/DocumentReference.rs patient/Encounter.rs patient/Goal.rs patient/Immunization.rs patient/Location.rs patient/MedicationRequest.rs patient/Observation.rs patient/Organization.rs patient/Patient.rs patient/Practitioner.rs patient/Procedure.rs patient/Provenance.rs patient/PractitionerRole.rs'
          },
          { name: :auth_request_method, default: 'GET', locked: true },
          { name: :use_discovery, locked: true },
          { name: :pkce_support, default: 'enabled', locked: true },
          { name: :pkce_code_challenge_method, default: 'S256', locked: true }
        ]
      }

    expect(auth_input.options[:components]).to match_array(expected_auth_input_options[:components])
  end
end
