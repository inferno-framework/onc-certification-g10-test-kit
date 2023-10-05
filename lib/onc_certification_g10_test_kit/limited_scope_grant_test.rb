module ONCCertificationG10TestKit
  class LimitedScopeGrantTest < Inferno::Test
    include G10Options

    title 'OAuth token exchange response grants scope that is limited to those selected by user'
    description %(
      The ONC certification criteria requires that patients are capable of
      choosing which FHIR resources to authorize to the application. For this
      test, the tester specifies which resources will be selected during
      authorization, and this verifies that only those resources are granted
      according to the scopes returned during the access token response.
    )
    id :g10_limited_scope_grant

    input :received_scopes, :expected_resources

    POSSIBLE_RESOURCES =
      [
        'AllergyIntolerance',
        'CarePlan',
        'CareTeam',
        'Condition',
        'Device',
        'DiagnosticReport',
        'DocumentReference',
        'Goal',
        'Immunization',
        'MedicationRequest',
        'Observation',
        'Procedure',
        'Patient'
      ].freeze

    V5_POSSIBLE_RESOURCES =
      (POSSIBLE_RESOURCES + ['Encounter', 'ServiceRequest']).freeze

    V6_POSSIBLE_RESOURCES =
      (V5_POSSIBLE_RESOURCES + ['Specimen', 'Coverage', 'MedicationDispense']).freeze

    def possible_resources
      return V5_POSSIBLE_RESOURCES if using_us_core_5?

      return V6_POSSIBLE_RESOURCES if using_us_core_6?

      POSSIBLE_RESOURCES
    end

    def scope_granting_access?(resource_type, scopes)
      scopes
        .select { |scope| scope.start_with?("patient/#{resource_type}", 'patient/*') }
        .any? do |scope|
          _type, resource_access = scope.split('/')
          _resource, access_level = resource_access.split('.')

          access_level.match?(/\A(\*|read|c?ru?d?s?\b)/)
        end
    end

    run do
      expected_resources_list = expected_resources.split(',').map(&:strip).map(&:downcase)
      allowed_resources =
        possible_resources.select { |resource_type| expected_resources_list.include? resource_type.downcase }
      forbidden_resources = possible_resources - allowed_resources

      received_scope_list = received_scopes.split

      improperly_granted_resources =
        forbidden_resources.select { |resource_type| scope_granting_access?(resource_type, received_scope_list) }
      improperly_denied_resources =
        allowed_resources.reject { |resource_type| scope_granting_access?(resource_type, received_scope_list) }

      assert improperly_granted_resources.empty?,
             'User expected to deny the following resources that were granted: ' \
             "#{improperly_granted_resources.join(', ')}"
      assert improperly_denied_resources.empty?,
             'User expected to grant access to the following resources: ' \
             "#{improperly_denied_resources.join(', ')}"

      assert forbidden_resources.present?,
             'This test requires at least one resource to be denied, but the received scopes ' \
             "`#{received_scopes}` grant access to all resource types."

      pass "Resources to be denied: #{forbidden_resources.join(', ')}"
    end
  end
end
