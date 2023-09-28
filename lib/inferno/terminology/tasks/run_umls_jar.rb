require_relative 'temp_dir'

module Inferno
  module Terminology
    module Tasks
      # More information on batch running UMLS
      # https://www.nlm.nih.gov/research/umls/implementation_resources/community/mmsys/BatchMetaMorphoSys.html
      class RunUMLSJar
        include TempDir

        VERSIONED_PROPS = {
          '2019' => 'inferno_2019.prop',
          '2020' => 'inferno_2020.prop',
          '2021' => 'inferno_2021.prop',
          '2022' => 'inferno_2022.prop',
          '2023' => 'inferno_2023.prop'
        }.freeze

        attr_reader :version

        def initialize(version:)
          @version = version
        end

        def run
          Inferno.logger.info "#{platform} system detected"
          config_file = File.join(Dir.pwd, 'resources', VERSIONED_PROPS[version])
          output_dir = File.join(Dir.pwd, versioned_temp_dir, 'umls_subset')
          FileUtils.mkdir(output_dir)

          Inferno.logger.info "Using #{config_file}"
          Dir.chdir(Dir[File.join(Dir.pwd, versioned_temp_dir, '/umls/20*')][0]) do
            Inferno.logger.info Dir.pwd
            Dir['lib/*.jar'].each do |jar|
              File.chmod(0o555, jar)
            end
            Dir["jre/#{platform}/bin/*"].each do |file|
              File.chmod(0o555, file)
            end

            Inferno.logger.info 'Running MetamorphoSys (this may take a while)...'
            output = system("./jre/#{platform}/bin/java " \
                            '-Djava.awt.headless=true ' \
                            '-cp .:lib/jpf-boot.jar ' \
                            '-Djpf.boot.config=./etc/subset.boot.properties ' \
                            '-Dlog4j.configuration=./etc/log4j.properties ' \
                            '-Dinput.uri=. ' \
                            "-Doutput.uri=#{output_dir} " \
                            "-Dmmsys.config.uri=#{config_file} " \
                            '-Xms300M -Xmx8G ' \
                            'org.java.plugin.boot.Boot')
            unless output
              Inferno.logger.info 'MetamorphoSys run failed'
              # The cwd at this point is 2 directories above where umls_subset
              # is, so we have to navigate up to it
              umls_subset_directory = File.join(Dir.pwd, '..', '..', 'umls_subset')
              FileUtils.remove_dir(umls_subset_directory) if File.directory?(umls_subset_directory)
              exit 1
            end
          end

          Inferno.logger.info 'done'
        end

        def platform
          if !(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
            'windows64'
          elsif !(/darwin/ =~ RUBY_PLATFORM).nil?
            'macos'
          else
            'linux'
          end
        end
      end
    end
  end
end
