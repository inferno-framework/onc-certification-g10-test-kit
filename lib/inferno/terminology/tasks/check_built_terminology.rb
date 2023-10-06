require 'yaml'

module Inferno
  module Terminology
    module Tasks
      class CheckBuiltTerminology
        NON_UMLS_SYSTEMS = [
          'http://hl7.org/fhir/ValueSet/mimetypes',
          'urn:ietf:bcp:13',
          'http://hl7.org/fhir/us/core/ValueSet/simple-language',
          'urn:ietf:bcp:47'
        ].freeze

        def run
          if mismatched_value_sets.blank?
            Inferno.logger.info 'Terminology built successfully.'
            return
          end

          if only_non_umls_mismatch?
            Inferno.logger.info <<~NON_UMLS
              Terminology built successfully.

              Some terminology not based on UMLS did not match, but this can be
              a result of these terminologies having a different update schedule
              than UMLS. As long as the actual number of codes is close to the
              expected number, this does not does not reflect a problem with the
              terminology build.
            NON_UMLS
          else
            Inferno.logger.info 'Terminology build results different than expected.'
          end

          mismatched_value_sets.each do |value_set|
            Inferno.logger.info mismatched_value_set_message(value_set)
          end

          return unless new_value_sets.present?

          Inferno.logger.info("\nThe following unexpected value set validators were created:")
          new_value_sets.each do |value_set|
            Inferno.logger.info("#{value_set[:url]}: #{value_set[:count]} codes")
          end
        end

        def expected_manifest
          YAML.load_file(File.join(__dir__, '..', 'expected_manifest.yml'))
        end

        def new_manifest_path
          @new_manifest_path ||=
            File.join(Dir.pwd, 'resources', 'terminology', 'validators', 'bloom', 'manifest.yml')
        end

        def new_manifest
          return [] unless File.exist? new_manifest_path

          @new_manifest ||= YAML.load_file(new_manifest_path)
        end

        def mismatched_value_sets
          @mismatched_value_sets ||=
            expected_manifest.reject do |expected_value_set|
              url = expected_value_set[:url]
              new_value_set(url) == expected_value_set
            end
        end

        def new_value_sets
          @new_value_sets ||=
            new_manifest.reject { |value_set| old_value_set?(value_set[:url]) }
        end

        def new_value_set(url)
          new_manifest.find { |value_set| value_set[:url] == url }
        end

        def old_value_set?(url)
          expected_manifest.any? { |value_set| value_set[:url] == url }
        end

        def only_non_umls_mismatch?
          mismatched_value_sets.all? { |value_set| NON_UMLS_SYSTEMS.include? value_set[:url] }
        end

        def mismatched_value_set_message(expected_value_set)
          url = expected_value_set[:url]
          actual_value_set = new_value_set(url)

          "#{url}: Expected codes: #{expected_value_set[:count]} Actual codes: #{actual_value_set&.dig(:count) || 0}"
        end
      end
    end
  end
end
