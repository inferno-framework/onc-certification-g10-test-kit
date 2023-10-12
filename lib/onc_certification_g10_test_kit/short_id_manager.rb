module ONCCertificationG10TestKit
  # @private
  # This module ensures that short test ids don't change
  module ShortIDManager
    class << self
      def all_children(runnable)
        runnable
          .children
          .flat_map { |child| [child] + all_children(child) }
      end

      def short_id_file_path
        File.join(__dir__, 'short_id_map.yml')
      end

      def short_id_map
        @short_id_map ||= YAML.load_file(short_id_file_path)
      end

      def assign_short_ids
        all_children(G10CertificationSuite).each do |runnable|
          short_id = short_id_map.fetch(runnable.id)
          runnable.define_singleton_method(:short_id) do
            short_id
          end
        rescue KeyError
          Inferno::Application['logger'].warn("No short id defined for #{runnable.id}")
        end
      rescue Errno::ENOENT
        Inferno::Application['logger'].warn("No short id map found")
      end

      ### The methods below are only for creating an initial list of short ids

      # Run this in an inferno console to save the current short ids
      def save_current_short_id_map
        File.write(short_id_file_path, current_short_id_map.to_yaml)
      end

      def current_short_id_map
        @current_short_id_map ||=
          all_children(G10CertificationSuite).each_with_object({}) do |runnable, mapping|
            mapping[runnable.id] = runnable.short_id
          end
      end
    end
  end
end
