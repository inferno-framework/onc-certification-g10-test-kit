require_relative 'profile_selector'

module ONCCertificationG10TestKit
  module BulkExportValidationTester
    include USCoreTestKit::MustSupportTest
    include ProfileSelector
    include G10Options

    attr_reader :metadata

    MAX_NUM_COLLECTED_LINES = 100
    MIN_RESOURCE_COUNT = 2
    OMIT_KLASS = ['Medication', 'Location', 'QuestionnaireResponse', 'PractitionerRole'].freeze
    PROFILES_TO_SKIP = [
      'http://hl7.org/fhir/us/core/StructureDefinition/us-core-simple-observation'
    ].freeze

    def metadata_list
      @metadata_list ||=
        versioned_us_core_module::USCoreTestSuite
          .metadata
          .select { |metadata| metadata.resource == resource_type }
          .reject { |metadata| PROFILES_TO_SKIP.include? metadata.profile_url }
    end

    def resources_from_all_files
      @resources_from_all_files ||= {}
    end

    def first_error
      @first_error ||= {}
    end

    def patient_ids_seen
      scratch[:patient_ids_seen] ||= []
    end

    def build_headers(use_token)
      headers = { accept: 'application/fhir+ndjson' }
      headers.merge!({ authorization: "Bearer #{bearer_token}" }) if use_token == 'true'
      headers
    end

    def stream_ndjson(endpoint, headers, process_chunk_line, process_response) # rubocop:disable Metrics/CyclomaticComplexity
      hanging_chunk = String.new

      process_body = proc { |chunk|
        hanging_chunk << chunk
        chunk_by_lines = hanging_chunk.lines

        hanging_chunk = chunk_by_lines.pop || String.new

        chunk_by_lines.each do |elem|
          process_chunk_line.call(elem)
        end
      }

      stream(process_body, endpoint, headers:)

      max_redirect = 5

      while [301, 302, 303, 307].include?(response[:status]) &&
            request.response_header('location')&.value.present? &&
            max_redirect.positive?

        max_redirect -= 1

        redirect_url = request.response_header('location')&.value

        # handle relative redirects
        redirect_url = URI.parse(endpoint).merge(redirect_url).to_s unless redirect_url.start_with?('http')

        redirect_headers = headers.except(:authorization)

        stream(process_body, redirect_url, headers: redirect_headers)
      end

      process_chunk_line.call(hanging_chunk)
      process_response.call(response)
    end

    def predefined_device_type?(resource) # rubocop:disable Metrics/CyclomaticComplexity
      return true if bulk_device_types_in_group.blank?

      expected = Set.new(bulk_device_types_in_group.split(',').map(&:strip))

      actual = resource&.type&.coding&.filter_map do |coding|
        coding.code if coding.system.nil? || coding.system == 'http://snomed.info/sct'
      end

      (expected & actual).any?
    end

    def determine_profile(resource)
      return if resource.resourceType == 'Device' && !predefined_device_type?(resource)

      select_profile(resource)
    end

    def validate_conformance(resources)
      metadata_list.each do |meta|
        next if resource_type == 'Location'

        skip_if resources[meta.profile_url].blank?,
                "No #{resource_type} resources found that conform to profile: #{meta.profile_url}."
        @metadata = meta
        @missing_elements = nil
        @missing_slices = nil
        @missing_extensions = nil
        begin
          perform_must_support_test(resources[meta.profile_url])
        rescue Inferno::Exceptions::PassException
          next
        rescue Inferno::Exceptions::SkipException => e
          e.message.concat " for `#{meta.profile_url}`"
          raise e
        end
      end
    end

    def versioned_profile_url(profile_url)
      profile_version = metadata_list.find { |metadata| metadata.profile_url == profile_url }&.profile_version

      profile_version ? "#{profile_url}|#{profile_version}" : profile_url
    end

    def check_file_request(url) # rubocop:disable Metrics/CyclomaticComplexity
      line_count = 0
      resources = Hash.new { |h, k| h[k] = [] }

      process_line = proc do |line|
        next unless lines_to_validate.blank? ||
                    line_count < lines_to_validate.to_i ||
                    (resource_type == 'Patient' && patient_ids_seen.length < MIN_RESOURCE_COUNT)

        line_count += 1

        begin
          resource = FHIR.from_contents(line)
        rescue StandardError
          skip "Server response at line \"#{line_count}\" is not a processable FHIR resource."
        end

        if resource.resourceType != resource_type
          assert false, "Resource type \"#{resource.resourceType}\" at line \"#{line_count}\" does not match type " \
                        "defined in output \"#{resource_type}\""
        end

        profile_urls = determine_profile(resource)
        profile_urls.each do |profile_url|
          resources[profile_url] << resource

          scratch[:patient_ids_seen] = patient_ids_seen | [resource.id] if resource_type == 'Patient'

          profile_with_version = versioned_profile_url(profile_url)
          unless resource_is_valid?(resource:, profile_url: profile_with_version)
            if first_error.key?(:line_number)
              @invalid_resource_count += 1
            else
              @invalid_resource_count = 1
              first_error[:line_number] = line_count
              first_error[:messages] = messages.dup
            end
          end
        end
      end

      process_headers = proc { |response|
        value = (response[:headers].find { |header| header.name.downcase == 'content-type' })&.value
        unless value&.start_with?('application/fhir+ndjson')
          skip "Content type must have 'application/fhir+ndjson' but found '#{value}'"
        end
      }

      stream_ndjson(url, build_headers(requires_access_token), process_line, process_headers)
      resources_from_all_files.merge!(resources) do |_key, all_resources, file_resources|
        all_resources | file_resources
      end
      line_count
    end

    def process_validation_errors(resource_count)
      return if @invalid_resource_count.nil? || @invalid_resource_count.zero?

      first_error_message = "The line number for the first failed resource is #{first_error[:line_number]}."

      messages.clear
      messages.concat(first_error[:messages])

      assert false,
             "#{@invalid_resource_count} / #{resource_count} #{resource_type} resources failed profile validation. " \
             "#{first_error_message}"
    end

    def perform_bulk_export_validation
      skip_if status_output.blank?, 'Could not verify this functionality when Bulk Status Output is not provided'
      skip_if (requires_access_token == 'true' && bearer_token.blank?),
              'Could not verify this functionality when Bearer Token is required and not provided'

      assert_valid_json(status_output)
      file_list = JSON.parse(status_output).select { |file| file['type'] == resource_type }
      if file_list.empty?
        message = "No #{resource_type} resource file item returned by server."
        omit_if (OMIT_KLASS.include? resource_type), "#{message} #{resource_type} resources are optional."
        skip message
      end

      @resources_from_all_files = {}
      resource_count = 0

      file_list.each do |file|
        resource_count += check_file_request(file['url'])
      end

      process_validation_errors(resource_count)

      validate_conformance(resources_from_all_files)

      pass "Successfully validated #{resource_count} #{resource_type} resource(s)."
    end
  end
end
