module ONCCertificationG10TestKit
  class SMARTScopesTest < Inferno::Test
    include G10Options

    title 'Patient-level access with OpenID Connect and Refresh Token scopes used.'
    description %(
      The scopes being input must follow the guidelines specified in the
      smart-app-launch guide. All scopes requested are expected to be granted.
    )
    id :g10_smart_scopes
    input :requested_scopes, :received_scopes
    uses_request :token

    VALID_RESOURCE_TYPES = [
      '*',
      'Patient',
      'AllergyIntolerance',
      'Binary',
      'CarePlan',
      'CareTeam',
      'Condition',
      'Device',
      'DiagnosticReport',
      'DocumentReference',
      'Encounter',
      'Goal',
      'Immunization',
      'Location',
      'Medication',
      'MedicationOrder',
      'MedicationRequest',
      'MedicationStatement',
      'Observation',
      'Organization',
      'Person',
      'Practitioner',
      'PractitionerRole',
      'Procedure',
      'Provenance',
      'RelatedPerson'
    ].freeze

    V5_VALID_RESOURCE_TYPES =
      (VALID_RESOURCE_TYPES + ['ServiceRequest', 'QuestionnaireResponse', 'Media']).freeze

    V6_VALID_RESOURCE_TYPES =
      (V5_VALID_RESOURCE_TYPES + ['Coverage', 'MedicationDispense', 'RelatedPerson', 'Specimen']).freeze

    V7_VALID_RESOURCE_TYPES = (V6_VALID_RESOURCE_TYPES + ['Location'])

    PATIENT_COMPARTMENT_RESOURCE_TYPES = [
      '*',
      'Patient',
      'AllergyIntolerance',
      'CarePlan',
      'CareTeam',
      'Condition',
      'DiagnosticReport',
      'DocumentReference',
      'Goal',
      'Immunization',
      'MedicationRequest',
      'Observation',
      'Procedure',
      'Provenance'
    ].freeze

    V5_PATIENT_COMPARTMENT_RESOURCE_TYPES =
      (PATIENT_COMPARTMENT_RESOURCE_TYPES + ['ServiceRequest']).freeze

    V6_PATIENT_COMPARTMENT_RESOURCE_TYPES =
      (V5_PATIENT_COMPARTMENT_RESOURCE_TYPES + ['Coverage', 'MedicationDispense', 'Specimen']).freeze

    V7_PATIENT_COMPARTMENT_RESOURCE_TYPES = (V6_PATIENT_COMPARTMENT_RESOURCE_TYPES + ['Location']).freeze

    attr_accessor :received_or_requested

    def patient_compartment_resource_types
      return V5_PATIENT_COMPARTMENT_RESOURCE_TYPES if using_us_core_5?

      return V6_PATIENT_COMPARTMENT_RESOURCE_TYPES if using_us_core_6?

      return V7_PATIENT_COMPARTMENT_RESOURCE_TYPES if using_us_core_7?

      PATIENT_COMPARTMENT_RESOURCE_TYPES
    end

    def valid_resource_types
      return V5_VALID_RESOURCE_TYPES if using_us_core_5?

      return V6_VALID_RESOURCE_TYPES if using_us_core_6?

      return V7_VALID_RESOURCE_TYPES if using_us_core_7?

      VALID_RESOURCE_TYPES
    end

    def required_scope_type
      config.options[:required_scope_type]
    end

    def required_scopes
      config.options[:required_scopes]
    end

    def scope_version
      case received_or_requested
      when 'received'
        config.options[:received_scope_version] || config.options[:scope_version]
      when 'requested'
        config.options[:requested_scope_version] || config.options[:scope_version]
      else
        config.options[:scope_version]
      end
    end

    def requested_scope_version
      config.options[:requested_scope_version]
    end

    def read_format
      v1_read_format = 'read'
      v2_read_format = 'c?ru?d?s?'

      case scope_version
      when :v1
        "#{v1_read_format} | *"
      when :v2, :v2_2
        "#{v2_read_format} | *"
      else
        [v1_read_format, v2_read_format, '*'].join(' | ')
      end
    end

    def access_level_regex
      case scope_version
      when :v1
        /\A(\*|read)\b/
      when :v2, :v2_2
        /\A(\*|c?ru?d?s?)\b/
      else
        /\A(\*|read|c?ru?d?s?)\b/
      end
    end

    def bad_format_message(scope, scope_direction = 'Requested')
      %(
        #{scope_direction} scope `#{scope}` does not follow the format:
        `#{required_scope_type}/[ <ResourceType> | * ].[ #{read_format} ]`
      )
    end

    def strip_experimental_scope_syntax(full_scope)
      if scope_version == :v1
        full_scope
      else
        full_scope.split('?').first
      end
    end

    def assert_correct_scope_type(scope, scope_type, resource_type, scope_direction)
      if required_scope_type == 'patient' && patient_compartment_resource_types.exclude?(resource_type)
        assert ['user', 'patient'].include?(scope_type),
               "#{scope_direction} scope '#{scope}' must begin with either 'user/' or 'patient/'"
      else
        assert scope_type == required_scope_type, bad_format_message(scope, scope_direction)
      end
    end

    def requested_scope_test(scopes)
      correct_scope_type_found = false

      scopes.each do |full_scope|
        scope = strip_experimental_scope_syntax(full_scope)

        scope_pieces = scope.split('/')
        assert scope_pieces.length == 2, bad_format_message(scope)

        scope_type, resource_scope = scope_pieces

        resource_scope_parts = resource_scope.split('.')
        assert resource_scope_parts.length == 2, bad_format_message(scope)

        resource_type, access_level = resource_scope_parts
        assert access_level =~ access_level_regex, bad_format_message(scope)

        assert_correct_scope_type(scope, scope_type, resource_type, 'Requested')

        assert valid_resource_types.include?(resource_type),
               "'#{resource_type}' must be either a permitted resource type or '*'"

        correct_scope_type_found = true if scope_type == required_scope_type
      end

      assert correct_scope_type_found,
             "#{required_scope_type.capitalize}-level scope in the format: " \
             "`#{required_scope_type}/[ <ResourceType> | * ].[ #{read_format} ]` was not requested."
    end

    def received_scope_test(scopes)
      granted_resource_types = []

      scopes.each do |full_scope|
        scope = strip_experimental_scope_syntax(full_scope)

        scope_pieces = scope.split('/')
        next unless scope_pieces.length == 2

        scope_type, resource_scope = scope_pieces

        resource_scope_parts = resource_scope.split('.')
        next unless resource_scope_parts.length == 2

        resource_type, access_level = resource_scope_parts
        next unless access_level =~ access_level_regex

        next unless ['patient', 'user', 'system'].include?(scope_type)

        assert_correct_scope_type(scope, scope_type, resource_type, 'Received')

        granted_resource_types << resource_type
      end

      missing_resource_types =
        if granted_resource_types.include?('*')
          []
        else
          patient_compartment_resource_types - granted_resource_types - ['*']
        end

      assert missing_resource_types.empty?,
             "Request scopes #{missing_resource_types.join(', ')} were not granted by authorization server."
    end

    run do
      skip_if request.status != 200, 'Token exchange was unsuccessful'

      [
        {
          scopes: requested_scopes,
          received_or_requested: 'requested'
        },
        {
          scopes: received_scopes,
          received_or_requested: 'received'
        }
      ].each do |metadata|
        scopes = metadata[:scopes].split
        self.received_or_requested = metadata[:received_or_requested]

        missing_scopes = required_scopes - scopes
        assert missing_scopes.empty?,
               "Required scopes were not #{received_or_requested}: #{missing_scopes.join(', ')}"

        scopes -= required_scopes

        # Other 'okay' scopes. Also scopes may include both 'launch' and
        # 'launch/patient' for EHR launch and Standalone launch.
        # 'launch/encounter' is mentioned by SMART App Launch though not in
        # (g)(10) test procedure
        scopes -= ['online_access', 'offline_access', 'launch', 'launch/patient', 'launch/encounter']

        if received_or_requested == 'requested'
          requested_scope_test(scopes)
        else
          received_scope_test(scopes)
        end
      end
    end
  end
end
