RSpec.describe ONCCertificationG10TestKit::SMARTGranularScopeSelectionTest do
  let(:test) { described_class }
  let(:suite_id) { 'g10_certification' }
  let(:requested_scopes) do
    [
      'launch',
      'openid',
      'fhirUser',
      'patient/Patient.read',
      'patient/Condition.read',
      'patient/Observation.read'
    ].join(' ')
  end
  let(:smart_auth_info) { Inferno::DSL::AuthInfo.new(requested_scopes:) }
  let(:received_scopes) do
    [
      'launch',
      'openid',
      'fhirUser',
      'patient/Patient.rs',
      'patient/Condition.rs?category=http://terminology.hl7.org/CodeSystem/condition-category|problem-list-item',
      'patient/Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|survey'
    ].join(' ')
  end

  it 'fails if a required resource-level scope is not requsted' do
    smart_auth_info.requested_scopes = 'patient/Patient.read'
    result = run(test, smart_auth_info:, received_scopes:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/No resource-level scope was requested/)
  end

  it 'skips if a granular scope is requested' do
    smart_auth_info.requested_scopes =
      "#{requested_scopes} patient/Observation.rs?category=" \
      'http://terminology.hl7.org/CodeSystem/observation-category|survey'

    result = run(test, smart_auth_info:, received_scopes:)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/Granular scope was requested/)
  end

  it 'fails if a resource-level Condition/Observation scope is received' do
    scopes_with_resource = "#{received_scopes} patient/Condition.rs"

    result = run(test, smart_auth_info:, received_scopes: scopes_with_resource)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Resource-level scope was granted/)
  end

  it 'fails if no granular Condition/Observation scope is received' do
    scopes_without_granular = 'launch openid fhirUser patient/Patient.rs'

    result = run(test, smart_auth_info:, received_scopes: scopes_without_granular)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/No granular scopes were granted/)
  end

  it 'fails if no Patient read scope is received' do
    scopes_without_patient = received_scopes.sub('patient/Patient.rs ', '')

    result = run(test, smart_auth_info:, received_scopes: scopes_without_patient)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/No v2 resource-level scope was granted for Patient/)
  end

  it 'fails if a v1 Patient read scope is received' do
    scopes_with_v1_patient = received_scopes.sub('patient/Patient.rs', 'patient/Patient.read')

    result = run(test, smart_auth_info:, received_scopes: scopes_with_v1_patient)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/No v2 resource-level scope was granted for Patient/)
  end

  it 'passes if resource-level scopes are requested, and granular Condition/Observation scopes are received' do
    result = run(test, smart_auth_info:, received_scopes:)

    expect(result.result).to eq('pass')
  end
end
