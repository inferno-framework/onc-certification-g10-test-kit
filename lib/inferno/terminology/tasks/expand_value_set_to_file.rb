module Inferno
  module Terminology
    module Tasks
      class ExpandValueSetToFile
        attr_reader :filename, :type, :value_set_url

        def initialize(vs:, filename:, type:) # rubocop:disable Naming/MethodParameterName
          @value_set_url = vs
          @filename = filename
          @type = type
        end

        def run
          # JSON is a special case, because we need to add codes from valuesets from several versions
          # We accomplish this by collecting and merging codes from each version
          # Before writing the JSON to a file at the end
          end_vs = nil if type == 'json'

          %w[2023].each do |version|
            Loader.register_umls_db File.join(TEMP_DIR, version, 'umls.db')
            Loader.load_value_sets_from_directory(PACKAGE_DIR, true)
            vs = Repositories::ValueSets.new.find(value_set_url)
            if type == 'json'
              end_vs ||= vs
              end_vs.value_set.merge vs.value_set
            else
              Loader.save_to_file(vs.valueset, filename, type.to_sym)
            end
          end

          File.open("#{filename}.json", 'wb') { |f| f << end_vs.expansion_as_fhir_valueset.to_json } if type == 'json'
        end
      end
    end
  end
end
