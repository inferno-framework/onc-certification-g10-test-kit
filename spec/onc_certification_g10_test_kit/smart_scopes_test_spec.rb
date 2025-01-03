RSpec.describe ONCCertificationG10TestKit::SMARTScopesTest do
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

  let(:test_session) { repo_create(:test_session, test_suite_id: 'g10_certification') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test) { described_class }
  let(:base_scopes) { 'offline_access launch' }

  before do
    repo_create(:request, test_session_id: test_session.id, name: :token)
    allow_any_instance_of(test).to receive(:required_scopes).and_return(base_scopes.split)
  end

  context 'with patient-level scopes' do
    before do
      allow_any_instance_of(test).to receive(:required_scope_type).and_return('patient')
    end

    context 'with requested scopes' do
      it 'fails if a required scope was not requested' do
        result = run(
          test,
          smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes: 'online_access launch'),
          received_scopes: 'foo'
        )

        expect(result.result).to eq('fail')
        expect(result.result_message).to eq('Required scopes were not requested: offline_access')
      end

      it 'fails if a scope has an invalid format' do
        ['patient/*/read', 'patient*.read', 'patient/*.*.read', 'patient/*.readx'].each do |bad_scope|
          result = run(
            test,
            smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes: "#{base_scopes} #{bad_scope}"),
            received_scopes: 'foo'
          )

          expect(result.result).to eq('fail')
          expect(result.result_message).to match('does not follow the format')
          expect(result.result_message).to include(bad_scope)
        end
      end

      it 'fails if a patient compartment resource has a user-level scope' do
        bad_scope = 'user/Patient.read'
        result = run(
          test,
          smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes: "#{base_scopes} user/Binary.read #{bad_scope}"),
          received_scopes: 'foo'
        )

        expect(result.result).to eq('fail')
        expect(result.result_message).to match('does not follow the format')
        expect(result.result_message).to include(bad_scope)
      end

      it 'fails if a scope for a disallowed resource type is requested' do
        bad_scope = 'patient/CodeSystem.read'
        result = run(
          test,
          smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes: "#{base_scopes} #{bad_scope}"),
          received_scopes: 'foo'
        )

        expect(result.result).to eq('fail')
        expect(result.result_message).to match('must be either a permitted resource type')
        expect(result.result_message).to include('CodeSystem')
      end

      it 'fails if no patient-level scopes were requested' do
        result = run(
          test,
          smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes: "#{base_scopes} user/Binary.read"),
          received_scopes: 'foo'
        )

        expect(result.result).to eq('fail')
        expect(result.result_message).to match('Patient-level scope in the format')
      end
    end

    context 'with v1 scopes' do
      it 'fails if v2 scopes are requested' do
        allow_any_instance_of(test).to receive(:scope_version).and_return(:v1)

        bad_scope = 'patient/Patient.r'
        result = run(
          test,
          smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes: "#{base_scopes} user/Binary.read #{bad_scope}"),
          received_scopes: 'foo'
        )

        expect(result.result).to eq('fail')
        expect(result.result_message).to match('does not follow the format')
        expect(result.result_message).to include(bad_scope)
      end
    end

    context 'with v2 scopes' do
      it 'fails if v1 scopes are requested' do
        allow_any_instance_of(test).to receive(:scope_version).and_return(:v2)

        bad_scope = 'patient/Patient.read'
        result = run(
          test,
          smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes: "#{base_scopes} user/Binary.rs #{bad_scope}"),
          received_scopes: 'foo'
        )

        expect(result.result).to eq('fail')
        expect(result.result_message).to match('does not follow the format')
        expect(result.result_message).to include(bad_scope)
      end
    end

    context 'with a specific request scope version' do
      it 'overrides a general version' do
        allow_any_instance_of(test).to(
          receive(:config).and_return(OpenStruct.new(options: { scope_version: :v1, requested_scope_version: :v2 }))
        )

        bad_scope = 'patient/Patient.read'
        result = run(
          test,
          smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes: "#{base_scopes} user/Binary.rs #{bad_scope}"),
          received_scopes: 'foo'
        )

        expect(result.result).to eq('fail')
        expect(result.result_message).to match('does not follow the format')
        expect(result.result_message).to include(bad_scope)
      end
    end

    context 'with received scopes' do
      let(:requested_scopes) { "#{base_scopes} patient/Patient.read" }

      it 'fails if a patient compartment resource has a user-level scope' do
        bad_scope = 'user/Patient.read'
        result = run(
          test,
          smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes:),
          received_scopes: "#{base_scopes} user/Binary.read #{bad_scope}"
        )

        expect(result.result).to eq('fail')
        expect(result.result_message).to match('does not follow the format')
        expect(result.result_message).to include(bad_scope)
      end

      it 'fails if the received scopes do not grant access to all required resource types' do
        result = run(
          test,
          smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes:),
          received_scopes: "#{base_scopes} patient/Patient.read"
        )

        expect(result.result).to eq('fail')
        expect(result.result_message).to match('were not granted by authorization server')
      end

      context 'with a specific received scope version' do
        it 'overrides a general version' do
          allow_any_instance_of(test).to(
            receive(:config).and_return(OpenStruct.new(options: { scope_version: :v1, received_scope_version: :v2 }))
          )
          bad_scope = 'patient/Patient.read'
          result = run(
            test,
            smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes:),
            received_scopes: "#{base_scopes} patient/Goal.rs #{bad_scope}"
          )

          expect(result.result).to eq('fail')
          expect(result.result_message).to match('were not granted')
          expect(result.result_message).to_not include('Goal')
          expect(result.result_message).to include('Patient')
        end
      end
    end
  end

  context 'with user-level scopes' do
    before do
      allow_any_instance_of(test).to receive(:required_scope_type).and_return('user')
    end

    context 'with requested scopes' do
      it 'fails if a patient-level scope is requested' do
        bad_scope = 'patient/Patient.read'
        result = run(
          test,
          smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes: "#{base_scopes} user/Binary.read #{bad_scope}"),
          received_scopes: 'foo'
        )

        expect(result.result).to eq('fail')
        expect(result.result_message).to match('does not follow the format')
        expect(result.result_message).to include(bad_scope)
      end

      it 'fails if no user-level scopes were requested' do
        result = run(
          test,
          smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes: base_scopes),
          received_scopes: 'foo'
        )

        expect(result.result).to eq('fail')
        expect(result.result_message).to match('User-level scope in the format')
      end
    end

    context 'with received scopes' do
      let(:requested_scopes) { "#{base_scopes} user/Binary.read" }

      it 'fails if a patient-level scope is received' do
        bad_scope = 'patient/Patient.read'
        result = run(
          test,
          smart_auth_info: Inferno::DSL::AuthInfo.new(requested_scopes:),
          received_scopes: "#{requested_scopes} #{bad_scope}"
        )

        expect(result.result).to eq('fail')
        expect(result.result_message).to match("Received scope `#{bad_scope}` does not follow the format")
        expect(result.result_message).to include(bad_scope)
      end
    end
  end
end
