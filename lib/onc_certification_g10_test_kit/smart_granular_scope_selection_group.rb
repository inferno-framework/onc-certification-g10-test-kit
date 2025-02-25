require_relative 'smart_scopes_test'
require_relative 'smart_granular_scope_selection_test'

module ONCCertificationG10TestKit
  class SmartGranularScopeSelectionGroup < Inferno::TestGroup
    title 'SMART Granular Scope Selection'
    short_title 'SMART Granular Scope Selection'
    id :g10_smart_granular_scope_selection

    input_instructions %(
      If necessary, register Inferno as a standalone application using the following information:

      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      Once the test is running, Inferno will perform a launch.  The tester must grant
      a sub-resource scope for each Conditoin and Observation, instead of granting
      access to all Condition and Observation resources:

      * “Condition” sub-resource scopes “Encounter Diagnosis”, “Problem List”,
          and “Health Concern”
      * “Observation” sub-resource scopes “Clinical Test”, “Laboratory”,
          “Social History”, “SDOH”, “Survey”, and “Vital Signs”

      Additionally, please grant access to the Patient scope.

    )

    description <<~DESCRIPTION
      This scenario verifies that when resource-level scopes are requested for
      Condition and Observation resources, the user is presented with the option
      of granting sub-resource scopes instead of the requested resource-level scope if desired.

      This scenario verifies that system behavior is consistent with the
      following clarification provided in the §170.315(g)(10) Standardized API
      for patient and population services [Certification Companion
      Guide](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services#ccg):

      > As part of supporting the SMART App Launch “permission-v2” capability
        for the purposes of certification, if an app requests authorization for
        a resource level scope for the “Condition” or “Observation” resources,
        then for patient authorization purposes a Health IT Module must support
        presentation of the required sub-resource scopes to the patient for
        authorization. Specifically, sub-resource scopes must be presented for
        patient authorization as follows:

      > * “Condition” sub-resource scopes “Encounter Diagnosis”, “Problem List”,
          and “Health Concern” if a “Condition” resource level scope is
          requested
      > * “Observation” sub-resource scopes “Clinical Test”, “Laboratory”,
          “Social History”, “SDOH”, “Survey”, and “Vital Signs” if an
          “Observation” resource level scope is requested

      The tests request SMART App Launch v2 resource-level Condition and
      Observation scopes. In each instance, the user must not grant the
      resource-level scopes and instead grant any valid sub-resource scope for
      Condition and Observation listed above. This scenario also requires that a
      resource-level Patient scope be granted.

      This scenario only verifies that sub-resource scopes are granted as returned by the
      authorization system during the SMART App Launch process, and does not
      attempt to access resources to verify accuracy of the granted scopes.

    DESCRIPTION

    run_as_group

    config(
      inputs: {
        received_scopes: { name: :granular_scope_selection_v2_received_scopes },
        smart_auth_info: {
          name: :granular_scopes_selection_smart_auth_info,
          title: 'Granular Scope Selection Credentials',
          options: {
            mode: 'auth',
            components: [
              Inferno::DSL::AuthInfo.default_auth_type_component_without_backend_services,
              {
                name: :use_discovery,
                locked: true
              },
              {
                name: :requested_scopes,
                default: %(
                  launch/patient openid fhirUser offline_access patient/Condition.rs
                  patient/Observation.rs patient/Patient.rs
                ).gsub(/\s{2,}/, ' ').strip
              },
              {
                name: :jwks,
                locked: true
              }
            ]
          }
        }
      },
      outputs: {
        smart_auth_info: { name: :granular_scopes_selection_smart_auth_info },
        received_scopes: { name: :granular_scope_selection_v2_received_scopes }
      }
    )

    group from: :smart_discovery_stu2,
          required_suite_options: G10Options::SMART_2_REQUIREMENT
    group from: :smart_discovery_stu2_2, # rubocop:disable Naming/VariableNumber
          required_suite_options: G10Options::SMART_2_2_REQUIREMENT

    group from: :smart_standalone_launch_stu2 do
      required_suite_options(G10Options::SMART_2_REQUIREMENT)
      id :g10_granular_scope_selection_v2_scopes
      title 'Granular Scope Selection with v2 Scopes'

      config(
        options: {
          redirect_message_proc: proc do |auth_url|
            %(
              ### #{self.class.parent&.parent&.title}

              [Follow this link to authorize with the SMART server](#{auth_url}).

              Tests will resume once Inferno receives a request at
              `#{config.options[:redirect_uri]}` with a state of `#{state}`.
            )
          end,
          ignore_missing_scopes_check: true
        }
      )

      test from: :g10_smart_scopes do
        config(
          options: {
            scope_version: :v2,
            required_scope_type: 'patient',
            required_scopes: ['openid', 'fhirUser', 'launch/patient', 'offline_access']
          }
        )

        def patient_compartment_resource_types
          ['Patient', 'Condition', 'Observation']
        end
      end

      test from: :g10_smart_granular_scope_selection
    end
    group from: :smart_standalone_launch_stu2_2 do # rubocop:disable Naming/VariableNumber
      required_suite_options(G10Options::SMART_2_2_REQUIREMENT)
      id :g10_granular_scope_selection_v2_2_scopes
      title 'Granular Scope Selection with v2 Scopes'

      config(
        options: {
          redirect_message_proc: proc do |auth_url|
            %(
              ### #{self.class.parent&.parent&.title}

              [Follow this link to authorize with the SMART server](#{auth_url}).

              Tests will resume once Inferno receives a request at
              `#{config.options[:redirect_uri]}` with a state of `#{state}`.
            )
          end,
          ignore_missing_scopes_check: true
        }
      )

      test from: :g10_smart_scopes do
        config(
          options: {
            scope_version: :v22,
            required_scope_type: 'patient',
            required_scopes: ['openid', 'fhirUser', 'launch/patient', 'offline_access']
          }
        )

        def patient_compartment_resource_types
          ['Patient', 'Condition', 'Observation']
        end
      end

      test from: :g10_smart_granular_scope_selection
    end
  end
end
