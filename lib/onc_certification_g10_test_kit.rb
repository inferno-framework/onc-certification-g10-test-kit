require 'smart_app_launch/smart_stu1_suite'
require 'smart_app_launch/smart_stu2_suite'
require 'us_core_test_kit'

require_relative 'onc_certification_g10_test_kit/configuration_checker'
require_relative 'onc_certification_g10_test_kit/version'

require_relative 'onc_certification_g10_test_kit/feature'
require_relative 'onc_certification_g10_test_kit/g10_options'
require_relative 'onc_certification_g10_test_kit/single_patient_api_group'
require_relative 'onc_certification_g10_test_kit/single_patient_us_core_4_api_group'
require_relative 'onc_certification_g10_test_kit/single_patient_us_core_5_api_group'
require_relative 'onc_certification_g10_test_kit/single_patient_us_core_6_api_group'
require_relative 'onc_certification_g10_test_kit/smart_app_launch_invalid_aud_group'
require_relative 'onc_certification_g10_test_kit/smart_invalid_token_group'
require_relative 'onc_certification_g10_test_kit/smart_invalid_token_group_stu2'
require_relative 'onc_certification_g10_test_kit/smart_invalid_pkce_group'
require_relative 'onc_certification_g10_test_kit/smart_limited_app_group'
require_relative 'onc_certification_g10_test_kit/smart_standalone_patient_app_group'
require_relative 'onc_certification_g10_test_kit/smart_ehr_practitioner_app_group'
require_relative 'onc_certification_g10_test_kit/smart_public_standalone_launch_group'
require_relative 'onc_certification_g10_test_kit/smart_public_standalone_launch_group_stu2'
require_relative 'onc_certification_g10_test_kit/smart_ehr_patient_launch_group'
require_relative 'onc_certification_g10_test_kit/smart_ehr_patient_launch_group_stu2'
require_relative 'onc_certification_g10_test_kit/multi_patient_api_stu1'
require_relative 'onc_certification_g10_test_kit/multi_patient_api_stu2'
require_relative 'onc_certification_g10_test_kit/terminology_binding_validator'
require_relative 'onc_certification_g10_test_kit/token_revocation_group'
require_relative 'onc_certification_g10_test_kit/visual_inspection_and_attestations_group'
require_relative 'inferno/terminology'
require_relative 'onc_certification_g10_test_kit/short_id_manager'

Inferno::Terminology::Loader.load_validators

module ONCCertificationG10TestKit
  class G10CertificationSuite < Inferno::TestSuite
    title 'ONC Certification (g)(10) Standardized API'
    short_title '(g)(10) Standardized API'
    version VERSION
    id :g10_certification
    links [
      {
        label: 'Report Issue',
        url: 'https://github.com/onc-healthit/onc-certification-g10-test-kit/issues/'
      },
      {
        label: 'Open Source',
        url: 'https://github.com/onc-healthit/onc-certification-g10-test-kit/'
      },
      {
        label: 'Download',
        url: 'https://github.com/onc-healthit/onc-certification-g10-test-kit/releases'
      }
    ]

    check_configuration do
      ConfigurationChecker.new.configuration_messages
    end

    WARNING_INCLUSION_FILTERS = [
      /Unknown CodeSystem/,
      /Unknown ValueSet/
    ].freeze

    [
      G10Options::US_CORE_3_REQUIREMENT,
      G10Options::US_CORE_4_REQUIREMENT,
      G10Options::US_CORE_5_REQUIREMENT,
      G10Options::US_CORE_6_REQUIREMENT

    ].each do |us_core_version_requirement|
      validator :default, required_suite_options: us_core_version_requirement do
        url ENV.fetch('G10_VALIDATOR_URL', 'http://validator_service:4567')

        us_core_message_filters =
          case (us_core_version_requirement[:us_core_version])
          when G10Options::US_CORE_3
            USCoreTestKit::USCoreV311::USCoreTestSuite::VALIDATION_MESSAGE_FILTERS
          when G10Options::US_CORE_4
            USCoreTestKit::USCoreV400::USCoreTestSuite::VALIDATION_MESSAGE_FILTERS
          when G10Options::US_CORE_5
            USCoreTestKit::USCoreV501::USCoreTestSuite::VALIDATION_MESSAGE_FILTERS
          when G10Options::US_CORE_6
            USCoreTestKit::USCoreV610::USCoreTestSuite::VALIDATION_MESSAGE_FILTERS
          end

        exclude_message do |message|
          if message.type == 'info' ||
             (message.type == 'warning' && WARNING_INCLUSION_FILTERS.none? do |filter|
                filter.match? message.message
              end) ||
             us_core_message_filters.any? { |filter| filter.match? message.message } ||
             (
               message.type == 'error' && (
                 message.message.match?(/\A\S+: \S+: Unknown Code/) ||
                 message.message.match?(/\A\S+: \S+: None of the codings provided are in the value set/) ||
                 message.message.match?(/\A\S+: \S+: The code provided \(\S*\) is not in the value set/) ||
                 message.message.match?(/\A\S+: \S+: The Coding provided \(\S*\) is not in the value set/)
               )
             )
            true
          else
            false
          end
        end

        perform_additional_validation do |resource, profile_url|
          versionless_profile_url, profile_version = profile_url.split('|')
          profile_version = case profile_version
                            when '6.1.0'
                              '610'
                            when '4.0.0'
                              '400'
                            when '5.0.1'
                              '501'
                            else
                              # This open-ended else is primarily for Vital Signs profiles in v3.1.1, which are tagged
                              # with the base FHIR version (4.0.1).  The profiles were migrated to US Core in later
                              # versions.
                              '311'
                            end

          us_core_suite = USCoreTestKit.const_get("USCoreV#{profile_version}")::USCoreTestSuite
          metadata = us_core_suite.metadata.find do |metadata_candidate|
            metadata_candidate.profile_url == versionless_profile_url
          end
          next if metadata.nil?

          validation_messages = if resource.instance_of?(FHIR::Provenance)
                                  USCoreTestKit::ProvenanceValidator.validate(resource)
                                else
                                  []
                                end

          terminology_validation_messages = metadata.bindings
            .select { |binding_definition| binding_definition[:strength] == 'required' }
            .flat_map do |binding_definition|
              TerminologyBindingValidator.validate(resource, binding_definition)
          rescue Inferno::UnknownValueSetException, Inferno::UnknownCodeSystemException => e
            { type: 'warning', message: e.message }
            end.compact

          validation_messages.concat(terminology_validation_messages)
          validation_messages
        end
      end
    end

    def self.jwks_json
      bulk_data_jwks = JSON.parse(File.read(
                                    ENV.fetch('G10_BULK_DATA_JWKS',
                                              File.join(__dir__, 'onc_certification_g10_test_kit',
                                                        'bulk_data_jwks.json'))
                                  ))
      @jwks_json ||= JSON.pretty_generate(
        { keys: bulk_data_jwks['keys'].select { |key| key['key_ops']&.include?('verify') } }
      )
    end

    def self.well_known_route_handler
      ->(_env) { [200, { 'Content-Type' => 'application/json' }, [jwks_json]] }
    end

    route(
      :get,
      '/.well-known/jwks.json',
      well_known_route_handler
    )

    suite_option :us_core_version,
                 title: 'US Core Version',
                 list_options: [
                   {
                     label: 'US Core 3.1.1 / USCDI v1',
                     value: G10Options::US_CORE_3
                   },
                   {
                     label: 'US Core 4.0.0 / USCDI v1',
                     value: G10Options::US_CORE_4
                   },
                   {
                     label: 'US Core 5.0.1 / USCDI v2',
                     value: G10Options::US_CORE_5
                   },
                   {
                     label: 'US Core 6.1.0 / USCDI v3',
                     value: G10Options::US_CORE_6
                   }
                 ]

    suite_option :smart_app_launch_version,
                 title: 'SMART App Launch Version',
                 list_options: [
                   {
                     label: 'SMART App Launch 1.0.0',
                     value: G10Options::SMART_1
                   },
                   {
                     label: 'SMART App Launch 2.0.0',
                     value: G10Options::SMART_2
                   }
                 ]

    suite_option :multi_patient_version,
                 title: 'Bulk Data Version',
                 list_options: [
                   {
                     label: 'Bulk Data 1.0.1',
                     value: G10Options::BULK_DATA_1
                   },
                   {
                     label: 'Bulk Data 2.0.0',
                     value: G10Options::BULK_DATA_2
                   }
                 ]

    config(
      inputs: {
        client_auth_encryption_method: {
          title: 'Client Authentication Encryption Method',
          locked: true
        }
      },
      options: {
        post_authorization_uri: "#{Inferno::Application['base_url']}/custom/smart_stu2/post_auth",
        incorrectly_permitted_tls_version_message_type: 'warning'
      }
    )

    description %(
      The ONC Certification (g)(10) Standardized API Test Kit is a testing tool for
      Health Level 7 (HL7®) Fast Healthcare Interoperability Resources (FHIR®)
      services seeking to meet the requirements of the Standardized API for
      Patient and Population Services criterion § 170.315(g)(10) in the 2015
      Edition Cures Update.

      To get started, please first register the Inferno client as a SMART App
      with the following information:

      * SMART Launch URI: `#{SMARTAppLaunch::AppLaunchTest.config.options[:launch_uri]}`
      * OAuth Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      For the multi-patient API, register Inferno with the following JWK Set
      Url:

      * `#{Inferno::Application[:base_url]}/custom/g10_certification/.well-known/jwks.json`

      Systems must pass all tests in order to qualify for ONC certification.
    )

    suite_summary %(
      The ONC Certification (g)(10) Standardized API Test Kit is a testing tool
      for Health Level 7 (HL7®) Fast Healthcare Interoperability Resources
      (FHIR®) services seeking to meet the requirements of the Standardized API
      for Patient and Population Services criterion § 170.315(g)(10) in the 2015
      Edition Cures Update rule.

      Systems may adopt later versions of standards than those named in the rule
      as approved by the ONC Standards Version Advancement Process (SVAP).
      Please select which approved version of each standard to use, and click
      ‘Start Testing’ to begin testing.
    )

    input_instructions %(
        Register Inferno as a SMART app using the following information:

        * Launch URI: `#{SMARTAppLaunch::AppLaunchTest.config.options[:launch_uri]}`
        * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

        For the multi-patient API, register Inferno with the following JWK Set
        Url:

        * `#{Inferno::Application[:base_url]}/custom/g10_certification/.well-known/jwks.json`
      )

    group from: 'g10_smart_standalone_patient_app'

    group from: 'g10_smart_limited_app'

    group from: 'g10_smart_ehr_practitioner_app'

    group from: 'g10_single_patient_api',
          required_suite_options: G10Options::US_CORE_3_REQUIREMENT
    group from: 'g10_single_patient_us_core_4_api',
          required_suite_options: G10Options::US_CORE_4_REQUIREMENT
    group from: 'g10_single_patient_us_core_5_api',
          required_suite_options: G10Options::US_CORE_5_REQUIREMENT
    group from: 'g10_single_patient_us_core_6_api',
          required_suite_options: G10Options::US_CORE_6_REQUIREMENT

    group from: 'multi_patient_api',
          required_suite_options: G10Options::BULK_DATA_1_REQUIREMENT
    group from: 'multi_patient_api_stu2',
          required_suite_options: G10Options::BULK_DATA_2_REQUIREMENT

    group do
      title 'Additional Tests'
      id 'Group06'
      description %(
        Not all requirements that need to be tested fit within the previous
        scenarios. The tests contained in this section addresses remaining
        testing requirements. Each of these tests need to be run independently.
        Please read the instructions for each in the 'About' section, as they
        may require special setup on the part of the tester.
      )

      default_redirect_message_proc = lambda do |auth_url|
        %(
          ### #{self.class.parent.title}

          [Follow this link to authorize with the SMART server](#{auth_url}).

          Tests will resume once Inferno receives a request at
          `#{config.options[:redirect_uri]}` with a state of `#{state}`.
        )
      end

      group from: :g10_public_standalone_launch,
            required_suite_options: G10Options::SMART_1_REQUIREMENT,
            config: { options: { redirect_message_proc: default_redirect_message_proc } }
      group from: :g10_public_standalone_launch_stu2,
            required_suite_options: G10Options::SMART_2_REQUIREMENT,
            config: { options: { redirect_message_proc: default_redirect_message_proc } }

      group from: :g10_token_revocation

      group from: :g10_smart_invalid_aud,
            config: { options: { redirect_message_proc: default_redirect_message_proc } }

      group from: :g10_smart_invalid_token_request,
            required_suite_options: G10Options::SMART_1_REQUIREMENT,
            config: { options: { redirect_message_proc: default_redirect_message_proc } }
      group from: :g10_smart_invalid_token_request_stu2,
            required_suite_options: G10Options::SMART_2_REQUIREMENT,
            config: { options: { redirect_message_proc: default_redirect_message_proc } }

      group from: :g10_smart_invalid_pkce_code_verifier_group,
            required_suite_options: G10Options::SMART_2_REQUIREMENT

      group from: :g10_ehr_patient_launch,
            required_suite_options: G10Options::SMART_1_REQUIREMENT
      group from: :g10_ehr_patient_launch_stu2,
            required_suite_options: G10Options::SMART_2_REQUIREMENT

      group from: :g10_visual_inspection_and_attestations
    end
  end
end

ONCCertificationG10TestKit::ShortIDManager.assign_short_ids
