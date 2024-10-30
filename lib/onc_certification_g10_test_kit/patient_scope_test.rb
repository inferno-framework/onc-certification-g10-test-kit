module ONCCertificationG10TestKit
  class PatientScopeTest < Inferno::Test
    title 'Patient-level scopes were granted'
    description %(
      Systems are required to support the `permission-patient` capability as
      part of the Clinician Access for EHR Launch Capability Set.

      This test verifies that systems are capable of granting patient-level
      scopes during an EHR Launch.

      * [Clinician Access for EHR Launch Capability Set STU
        1](http://hl7.org/fhir/smart-app-launch/1.0.0/conformance/index.html#clinician-access-for-ehr-launch)
      * [Clinician Access for EHR Launch Capability Set STU
        2](http://hl7.org/fhir/smart-app-launch/STU2/conformance.html#clinician-access-for-ehr-launch)
    )
    id :g10_patient_scope
    input :received_scopes

    def scope_version
      config.options[:scope_version]
    end

    run do
      expected_scopes =
        if scope_version == :v2 || scope_version == :v2_2
          [
            Regexp.new(scope_regex_string('patient/Patient.rs').gsub('.rs', '.r?s')),
            Regexp.new(scope_regex_string('patient/Patient.rs').gsub('.rs', '.rs?'))
          ]
        else
          [Regexp.new(scope_regex_string('patient/Patient.read'))]
        end

      received_scopes = self.received_scopes.split

      unmatched_scopes =
        expected_scopes.reject do |expected_scope|
          received_scopes.any? { |received_scope| received_scope.match? expected_scope }
        end

      assert unmatched_scopes.blank?,
             "No scope matching the following was received: `#{unmatched_scopes_string(unmatched_scopes)}`"
    end

    def scope_regex_string(scope)
      "\\A#{Regexp.quote(scope)}\\z"
    end

    def unmatched_scopes_string(unmatched_scopes)
      unmatched_scopes
        .map { |scope| "`#{scope.source}`" }
        .join(', ')
    end
  end
end
