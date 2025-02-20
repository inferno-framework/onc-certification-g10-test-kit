module ONCCertificationG10TestKit
  class SMARTGranularScopeSelectionTest < Inferno::Test
    title 'Granular Scope Selection'
    description %(
      This test verifies that granular scopes have been issued for Condition and
      Observation resources, and that a v2 read scope has been issued for the
      Patient resource.
    )
    id :g10_smart_granular_scope_selection
    input :received_scopes
    input :smart_auth_info, type: :auth_info

    def resources_with_granular_scopes
      ['Condition', 'Observation']
    end

    def resource_level_scope_regex(resource_type)
      /#{resource_type}\.(\*|read|c?ru?d?s?)\z/
    end

    def v2_resource_level_scope_regex(resource_type)
      /#{resource_type}\.(\*|c?ru?d?s?)\z/
    end

    def granular_scope_regex(resource_type)
      /#{resource_type}\.(\*|c?ru?d?s?)\?.+=.+/
    end

    run do
      assert smart_auth_info.requested_scopes.present?
      requested_scopes = smart_auth_info.requested_scopes.split
      (resources_with_granular_scopes + ['Patient']).each do |resource_type|
        assert requested_scopes.any? { |scope| scope.match(resource_level_scope_regex(resource_type)) },
               "No resource-level scope was requested for #{resource_type}"

        granular_scope = requested_scopes.find { |scope| scope.match(granular_scope_regex(resource_type)) }
        skip_if granular_scope.present?, "Granular scope was requested: #{granular_scope}"
      end

      assert received_scopes.present?
      received_scopes = self.received_scopes.split

      resources_with_granular_scopes.each do |resource_type|
        resource_level_scope = received_scopes.find { |scope| scope.match?(resource_level_scope_regex(resource_type)) }
        assert resource_level_scope.nil?, "Resource-level scope was granted: #{resource_level_scope}"
        assert received_scopes.any? { |scope| scope.match?(granular_scope_regex(resource_type)) },
               "No granular scopes were granted for #{resource_type}"
      end

      assert received_scopes.any? { |scope| scope.match?(v2_resource_level_scope_regex('Patient')) },
             'No v2 resource-level scope was granted for Patient'
    end
  end
end
