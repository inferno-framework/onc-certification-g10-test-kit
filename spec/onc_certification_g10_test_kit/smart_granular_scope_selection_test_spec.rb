RSpec.describe ONCCertificationG10TestKit::SMARTGranularScopeSelectionTest do
  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: runnable.config.input_type(name)
      )
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  end

  let(:test) { described_class }
  let(:suite_id) { 'g10_certification' }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
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
    result = run(test, requested_scopes: 'patient/Patient.read', received_scopes:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/No resource-level scope was requested/)
  end

  it 'skips if a granular scope is requested' do
    scopes_with_granular = "#{requested_scopes} patient/Observation.rs?category=" \
                           'http://terminology.hl7.org/CodeSystem/observation-category|survey'

    result = run(test, requested_scopes: scopes_with_granular, received_scopes:)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/Granular scope was requested/)
  end

  it 'fails if a resource-level Condition/Observation scope is received' do
    scopes_with_resource = "#{received_scopes} patient/Condition.rs"

    result = run(test, requested_scopes:, received_scopes: scopes_with_resource)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Resource-level scope was granted/)
  end

  it 'fails if no granular Condition/Observation scope is received' do
    scopes_without_granular = 'launch openid fhirUser patient/Patient.rs'

    result = run(test, requested_scopes:, received_scopes: scopes_without_granular)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/No granular scopes were granted/)
  end

  it 'fails if no Patient read scope is received' do
    scopes_without_patient = received_scopes.sub('patient/Patient.rs ', '')

    result = run(test, requested_scopes:, received_scopes: scopes_without_patient)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/No v2 resource-level scope was granted for Patient/)
  end

  it 'fails if a v1 Patient read scope is received' do
    scopes_with_v1_patient = received_scopes.sub('patient/Patient.rs', 'patient/Patient.read')

    result = run(test, requested_scopes:, received_scopes: scopes_with_v1_patient)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/No v2 resource-level scope was granted for Patient/)
  end

  it 'passes if resource-level scopes are requested, and granular Condition/Observation scopes are received' do
    result = run(test, requested_scopes:, received_scopes:)

    expect(result.result).to eq('pass')
  end
end
