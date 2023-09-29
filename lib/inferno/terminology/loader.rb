# frozen_string_literal: true

require 'active_support'
require 'active_support/all'
require 'bloomer'
require 'bloomer/msgpackable'
require 'fileutils'
require 'pry'

require_relative '../exceptions'
require_relative '../ext/bloomer'
require_relative '../repositiories/validators'
require_relative '../repositiories/value_sets'
require_relative 'fhir_package_manager'
require_relative 'value_set'
require_relative 'validator'

module Inferno
  module Terminology
    class Loader
      SKIP_SYS = [
        'http://hl7.org/fhir/ValueSet/message-events', # has 0 codes
        'http://hl7.org/fhir/ValueSet/care-team-category', # has 0 codes
        'http://hl7.org/fhir/ValueSet/action-participant-role', # has 0 codes
        'http://hl7.org/fhir/ValueSet/example-filter', # has fake property acme-plasma
        'http://hl7.org/fhir/ValueSet/all-distance-units', # UCUM filter "canonical"
        'http://hl7.org/fhir/ValueSet/all-time-units', # UCUM filter "canonical"
        'http://hl7.org/fhir/ValueSet/example-intensional', # Unhandled filter parent =
        'http://hl7.org/fhir/ValueSet/use-context', # ValueSet contains an unknown ValueSet
        'http://hl7.org/fhir/ValueSet/media-modality', # ValueSet contains an unknown ValueSet
        'http://hl7.org/fhir/ValueSet/example-hierarchical' # Example valueset with fake codes
      ].freeze

      @value_sets_repo = Inferno::Repositories::ValueSets.new
      @validators_repo = Inferno::Repositories::Validators.new

      @missing_validators = nil

      class << self
        attr_reader :validators_repo, :value_sets_repo

        def load_value_sets_from_directory(directory, include_subdirectories = false) # rubocop:disable Style/OptionalBooleanParameter
          directory += '/**/' if include_subdirectories
          value_set_files = Dir["#{directory}/*.json"]
          value_set_files.each do |vs_file|
            next unless JSON.parse(File.read(vs_file))['resourceType'] == 'ValueSet'

            add_value_set_from_file(vs_file)
          end
        end

        def add_alternative_code_system_names(code_systems)
          code_systems << 'urn:oid:2.16.840.1.113883.6.285' if code_systems.include? 'http://www.cms.gov/Medicare/Coding/HCPCSReleaseCodeSets'
          code_systems << 'urn:oid:2.16.840.1.113883.6.13' if code_systems.include? 'http://ada.org/cdt'
          if code_systems.include? 'http://www.ada.org/cdt'
            code_systems << 'http://ada.org/cdt'
            code_systems << 'urn:oid:2.16.840.1.113883.6.13'
          end
          code_systems << 'urn:oid:2.16.840.1.113883.6.101' if code_systems.include? 'http://nucc.org/provider-taxonomy'
          code_systems.uniq!
        end

        # Creates the valueset validators, based on the passed in parameters and
        # the value_sets_repo
        #
        # @param type [Symbol] the type of validators to create, either :bloom or
        #   :csv
        # @param [String] minimum_binding_strength the lowest binding strength for
        #   which we should build validators
        # @param [Boolean] include_umls a flag to determine if we should build
        #   validators that require UMLS
        # @param [Boolean] delete_existing a flag to determine whether any
        #   existing validators of `type` should be deleted before the creation
        #   tasks run. Default to `true`. If `false`, the existing validators will
        #   be read in and combined with the validators created in this step.
        def create_validators(
          type: :bloom,
          minimum_binding_strength: 'example',
          include_umls: true,
          delete_existing: true
        )
          strengths = ['example', 'preferred', 'extensible', 'required'].drop_while do |s|
            s != minimum_binding_strength
          end
          umls_code_systems = Set.new(ValueSet::SAB.keys)
          root_dir = "resources/terminology/validators/#{type}"

          FileUtils.rm_r(root_dir, force: true) if delete_existing
          FileUtils.mkdir_p(root_dir)

          vs_validators = get_value_sets(strengths).map do |vs_url, vs|
            next if SKIP_SYS.include? vs_url
            next if !include_umls && !umls_code_systems.disjoint?(Set.new(vs.included_code_systems))

            Inferno.logger.debug "Processing #{vs_url}"
            filename = "#{root_dir}/#{(URI(vs.url).host + URI(vs.url).path).gsub(%r{[./]}, '_')}"
            begin
              # Save the validator to file, and get the "new" count of number of codes
              new_count = save_to_file(vs.value_set, filename, type)
              code_systems = vs.all_included_code_systems
              Inferno.logger.debug "  #{new_count} codes"
              next if new_count.zero?

              add_alternative_code_system_names(code_systems)
              {
                url: vs_url,
                file: name_by_type(File.basename(filename), type),
                count: new_count,
                type: type.to_s,
                code_systems:
              }
            rescue UnknownCodeSystemException,
                   FilterOperationException,
                   UnknownValueSetException,
                   URI::InvalidURIError => e
              Inferno.logger.warn "#{e.message} for ValueSet: #{vs_url}"
              next
            end
          end
          vs_validators.compact!

          code_systems = vs_validators.flat_map { |validator| validator[:code_systems] }.uniq
          vs = ValueSet.new(@db)

          cs_validators = code_systems.map do |cs_name|
            next if SKIP_SYS.include? cs_name
            next if !include_umls && umls_code_systems.include?(cs_name)

            Inferno.logger.debug "Processing #{cs_name}"
            begin
              cs = vs.code_system_set(cs_name)
              filename = "#{root_dir}/#{bloom_file_name(cs_name)}"
              new_count = save_to_file(cs, filename, type)

              {
                url: cs_name,
                file: name_by_type(File.basename(filename), type),
                count: new_count,
                type: type.to_s,
                code_systems: cs_name
              }
            rescue UnknownCodeSystemException,
                   FilterOperationException,
                   UnknownValueSetException,
                   URI::InvalidURIError => e
              Inferno.logger.warn "#{e.message} for CodeSystem #{cs_name}"
              next
            end
          end
          validators = (vs_validators + cs_validators).compact

          # Write manifest for loading later
          File.write("#{root_dir}/manifest.yml", validators.to_yaml)

          create_code_system_metadata(cs_validators.map { |validator| validator[:url] }, root_dir)
        end

        def create_code_system_metadata(system_urls, root_dir)
          vs = ValueSet.new(@db)
          metadata_path = "#{root_dir}/metadata.yml"
          metadata =
            if File.file? metadata_path
              YAML.load_file(metadata_path)
            else
              {}
            end
          system_urls.each do |url|
            abbreviation = vs.umls_abbreviation(url)
            next if abbreviation.nil?

            versions = @db.execute("SELECT SVER FROM mrsab WHERE RSAB='#{abbreviation}' AND SABIN='Y'").flatten
            restriction_level = @db.execute(
              "SELECT SRL FROM mrsab WHERE RSAB='#{abbreviation}' AND SABIN='Y'"
            ).flatten.first
            system_metadata = metadata[url] || vs.code_system_metadata(url).dup || {}
            system_metadata[:versions] ||= []
            system_metadata[:versions].concat(versions).uniq!
            system_metadata[:restriction_level] = restriction_level

            metadata[url] = system_metadata
          end

          File.write(metadata_path, metadata.to_yaml)
        end

        def value_sets_to_load
          @value_sets_to_load ||=
            YAML.load_file(File.join('resources', 'value_sets.yml'))
        end

        # Run this method in an inferno console to update the list of value set
        # bindings. This is not done automatically during the build because
        # Inferno isn't loaded during the build process.
        def save_new_value_set_list
          all_metadata =
            USCoreTestKit::USCoreV311::USCoreTestSuite.metadata +
            USCoreTestKit::USCoreV400::USCoreTestSuite.metadata +
            USCoreTestKit::USCoreV501::USCoreTestSuite.metadata +
            USCoreTestKit::USCoreV610::USCoreTestSuite.metadata

          all_metadata =
            all_metadata
              .flat_map { |metadata| metadata.bindings.map { |bind| bind.merge(profile_url: metadata.profile_url) } }
              .select { |metadata| metadata[:strength] == 'required' }
              .uniq

          File.write(File.join('resources', 'value_sets.yml'), all_metadata.to_yaml)
        end

        # NOTE: resources/value_sets.yml controls which value sets get loaded.
        # It is currently manually generated from the US Core metadata.
        def get_value_sets(strengths)
          expected_vs_urls =
            value_sets_to_load
              .select { |vs| strengths.include? vs[:strength] }
              .map! { |vs| vs[:system] }
              .compact
              .uniq

          available_value_sets = value_sets_repo.select_by_url(expected_vs_urls)

          # Throw an error message for each missing valueset
          # But don't halt the rake task
          (expected_vs_urls - available_value_sets.keys).each do |missing_vs_url|
            Inferno.logger.error "Inferno doesn't know about valueset #{missing_vs_url}"
          end
          available_value_sets
        end

        # Chooses which filetype to save the validator as, based on the type variable passed in
        def save_to_file(codeset, filename, type)
          if codeset.blank?
            Inferno.logger.debug "Unable to save #{filename} because it contains no codes"
            return 0
          end

          case type
          when :bloom
            save_bloom_to_file(codeset, name_by_type(filename, type))
          when :csv
            save_csv_to_file(codeset, name_by_type(filename, type))
          else
            raise 'Unknown Validator Type!'
          end
        end

        def name_by_type(filename, type)
          case type
          when :bloom
            "#{filename}.msgpack"
          when :csv
            "#{filename}.csv"
          else
            raise 'Unknown Validator Type!'
          end
        end

        # Saves the valueset bloomfilter to a msgpack file
        #
        # @param [String] filename the name of the file
        def save_bloom_to_file(codings, filename)
          # If the file already exists, load it in
          bloom_filter =
            if File.file? filename
              Bloomer::Scalable.from_msgpack(File.read(filename))
            else
              Bloomer::Scalable.create_with_sufficient_size(codings.length)
            end
          codings.each do |coding|
            bloom_filter.add_without_duplication("#{coding[:system]}|#{coding[:code]}")
          end
          bloom_file = File.new(filename, 'wb')
          bloom_file.write(bloom_filter.to_msgpack) unless bloom_filter.nil?

          bloom_filter.count
        end

        # Saves the valueset to a csv
        # @param [String] filename the name of the file
        def save_csv_to_file(codings, filename)
          # If the file already exists, add it to the Set
          csv_set = Set.new
          if File.file? filename
            CSV.read(filename).each do |code_array|
              csv_set.add({ code: code_array[1], system: code_array[0] })
            end
          end
          codings.merge csv_set

          CSV.open(filename, 'wb') do |csv|
            codings.each do |coding|
              csv << [coding[:system], coding[:code]]
            end
          end
          codings.length
        end

        def register_umls_db(database)
          FileUtils.mkdir_p File.dirname(database)
          @db = SQLite3::Database.new database
        end

        def add_value_set_from_file(vs_file)
          vs = ValueSet.new(@db)
          vs.read_value_set(vs_file)
          value_sets_repo.insert(vs)
          vs
        end

        def load_validators(directory = 'resources/terminology/validators/bloom')
          manifest_file = "#{directory}/manifest.yml"
          return unless File.file? manifest_file

          validator_metadata = YAML.load_file(manifest_file)
          validator_metadata.each do |metadata|
            metadata[:bloom_filter] =
              Bloomer::Scalable.from_msgpack(File.read("#{directory}/#{metadata[:file]}"))
            validators_repo.insert(Validator.new(metadata))
          end
        end

        def bloom_file_name(codesystem)
          system = codesystem.tr('|', '_')
          uri = URI(system)
          return (uri.host + uri.path).gsub(%r{[./]}, '_') if uri.host && uri.port

          system.gsub(/\W/, '_')
        end

        def missing_validators
          return @missing_validators if @missing_validators

          required_value_sets =
            value_sets_repo
              .select_by_binding_strength(['required', 'extensible', 'preferred'])
              .map(&:value_set_url)
          @missing_validators = required_value_sets.compact - validators_repo.all_urls
        end
      end
    end
  end
end
