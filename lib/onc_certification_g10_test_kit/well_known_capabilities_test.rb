module ONCCertificationG10TestKit
  class SMARTWellKnownCapabilitiesTest < Inferno::Test
    include G10Options

    title 'Well-known configuration declares support for required capabilities'
    description %(
      A SMART on FHIR server SHALL convey its capabilities to app developers
      by listing the SMART core capabilities supported by their
      implementation within the Well-known configuration file. This test
      ensures that the capabilities required by this scenario are properly
      documented in the Well-known file.
    )
    id :g10_smart_well_known_capabilities
    input :well_known_configuration

    run do
      skip_if well_known_configuration.blank?, 'No well-known SMART configuration found.'

      assert_valid_json(well_known_configuration)
      capabilities = JSON.parse(well_known_configuration)['capabilities']
      assert capabilities.is_a?(Array),
             "Expected the well-known capabilities to be an Array, but found #{capabilities.class.name}"

      required_capabilities = config.options[:required_capabilities] || []

      if (using_us_core_5? || using_us_core_6?) && required_capabilities.include?('launch-ehr')
        required_capabilities += ['context-ehr-encounter']
      end

      missing_capabilities = required_capabilities - capabilities
      assert missing_capabilities.empty?,
             "The following capabilities required for this scenario are missing: #{missing_capabilities.join(', ')}"
    end
  end
end
