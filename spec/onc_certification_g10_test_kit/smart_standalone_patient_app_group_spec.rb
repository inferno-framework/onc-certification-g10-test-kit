require_relative '../../lib/onc_certification_g10_test_kit/smart_standalone_patient_app_group'

RSpec.describe ONCCertificationG10TestKit::SmartStandalonePatientAppGroup do
  let(:suite_id) { 'g10_certification' }

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
            default: ONCCertificationG10TestKit::ScopeConstants::STANDALONE_SMART_1_SCOPES
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
                { label: 'Confidential Asymmetric', value: 'asymmetric' }
              ]
            },
            locked: true
          },
          {
            name: :requested_scopes,
            default: ONCCertificationG10TestKit::ScopeConstants::STANDALONE_SMART_2_SCOPES
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
                { label: 'Confidential Asymmetric', value: 'asymmetric' }
              ]
            },
            locked: true
          },
          {
            name: :requested_scopes,
            default: ONCCertificationG10TestKit::ScopeConstants::STANDALONE_SMART_2_SCOPES
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
