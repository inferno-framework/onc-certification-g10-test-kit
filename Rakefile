require 'pry'
require 'pry-byebug'

require_relative 'lib/inferno/terminology'
require_relative 'lib/inferno/terminology/fhir_package_manager'
require_relative 'lib/inferno/terminology/tasks'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError # rubocop:disable Lint/SuppressedException
end

namespace :db do
  desc 'Apply changes to the database'
  task :migrate do
    require 'inferno/config/application'
    require 'inferno/utils/migration'
    Inferno::Utils::Migration.new.run
  end
end

def Inferno.logger
  @logger ||= Logger.new($stdout)
end

Inferno.logger.formatter = proc do |_severity, _datetime, _progname, message|
  "#{message}\n"
end

default_version = '2023'

namespace :terminology do |_argv|
  desc 'download and execute UMLS terminology data'
  task :download_umls, [:apikey, :version] do |_t, args|
    args.with_defaults(version: default_version)
    Inferno::Terminology::Tasks::DownloadUMLS.new(**args.to_hash).run
  end

  desc 'unzip umls zip'
  task :unzip_umls, [:version] do |_t, args|
    args.with_defaults(version: default_version)
    Inferno::Terminology::Tasks::UnzipUMLS.new(**args.to_hash).run
  end

  desc 'run umls jar'
  task :run_umls, [:version] do |_t, args|
    args.with_defaults(version: default_version)
    Inferno::Terminology::Tasks::RunUMLSJar.new(**args.to_hash).run
  end

  desc 'cleanup all terminology files'
  task :cleanup, [] do |_t, _args|
    Inferno::Terminology::Tasks::Cleanup.new.run
  end

  desc 'cleanup terminology files except umls.db'
  task :cleanup_precursors, [:version] do |_t, args|
    args.with_defaults(version: default_version)
    Inferno::Terminology::Tasks::CleanupPrecursors.new(**args.to_hash).run
  end

  desc 'post-process UMLS terminology file'
  task :process_umls, [:version] do |_t, args|
    args.with_defaults(version: default_version)
    Inferno::Terminology::Tasks::ProcessUMLS.new(**args.to_hash).run
  end

  desc 'post-process UMLS terminology file for translations'
  task :process_umls_translations, [] do |_t, _args|
    Inferno::Terminology::Tasks::ProcessUMLSTranslations.new.run
  end

  # desc 'Create only non-UMLS validators'
  # task :create_non_umls_vs_validators, [:minimum_binding_strength, :delete_existing] do |_t, args|
  #   args.with_defaults(type: 'bloom',
  #                      minimum_binding_strength: 'example',
  #                      delete_existing: true)
  #   validator_type = args.type.to_sym
  #   Inferno::Terminology::Loader.load_value_sets_from_directory(Inferno::Terminology::PACKAGE_DIR, true)
  #   Inferno::Terminology::Loader.create_validators(type: validator_type,
  #                                          minimum_binding_strength: args.minimum_binding_strength,
  #                                          include_umls: false,
  #                                          delete_existing: args.delete_existing)
  # end

  desc 'Create ValueSet Validators'
  task :create_vs_validators, [:minimum_binding_strength, :version, :delete_existing, :type] do |_t, args|
    args.with_defaults(
      minimum_binding_strength: 'example',
      delete_existing: true,
      version: default_version,
      type: 'bloom'
    )
    Inferno::Terminology::Tasks::CreateValueSetValidators.new(**args.to_hash).run
  end

  desc 'Number of codes in ValueSet'
  task :codes_in_valueset, [:vs] do |_t, args|
    Inferno::Terminology::Tasks::CountCodesInValueSet.new(**args.to_hash).run
  end

  desc 'Expand and Save ValueSet to a file'
  task :expand_valueset_to_file, [:vs, :filename, :type] do |_t, args|
    Inferno::Terminology::Tasks::ExpandValueSetToFile.new(**args.to_hash).run
  end

  desc 'Download FHIR Package'
  task :download_package, [:package, :location] do |_t, args|
    Inferno::Terminology::FHIRPackageManager.get_package(args.package, args.location)
  end

  desc 'Download Terminology from FHIR Package'
  task :download_program_terminology do |_t, _args|
    Inferno::Terminology::Tasks::DownloadFHIRTerminology.new.run
  end

  desc 'Check if the code is in the specified ValueSet.  Omit the ValueSet to check against CodeSystem'
  task :check_code, [:code, :system, :valueset] do |_t, args|
    args.with_defaults(system: nil, valueset: nil)
    Inferno::Terminology::Tasks::ValidateCode.new(**args.to_hash).run
  end

  desc 'Check if the terminology filters have been built correctly'
  task :check_built_terminology do |_t, _args|
    Inferno::Terminology::Tasks::CheckBuiltTerminology.new.run
  end
end

namespace :g10_test_kit do
  desc 'Generate ONC Certification (g)(10) Test Kit Matrix'
  task :generate_matrix do
    require_relative 'lib/onc_certification_g10_test_kit/tasks/generate_matrix'
    ONCCertificationG10TestKit::Tasks::GenerateMatrix.new.run
  end
end
