require 'rubygems/package'
require 'tempfile'
require 'zlib'
require 'json'

require_relative '../exceptions'

module Inferno
  module Terminology
    module FHIRPackageManager
      class << self
        REGISTRY_SERVER_URL = 'https://packages.fhir.org'.freeze
        REQUIRED_VSAC_VALUE_SET_URLS = [
          'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.4.11.836',
          'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.1.11.14914',
          'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.4.11.837',
          'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.4.11.877',
          'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1',
          'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1021.102',
          'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1021.103',
          'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.2074.1.1.3',
          'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1240.3'
          # The ValueSets below are needed when building all of the terminology
          # rather than only the terminology for required bindings.
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1186.8',
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1099.30',
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1010.6',
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1010.4',
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.11.20.9.38',
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.4.11.1066',
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.1.11.10267',
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1099.27',
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.88.12.80.17',
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1010.5',
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1021.32',
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1186.1',
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.88.12.80.17',
          # 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1186.2'
        ].freeze

        # Get the FHIR Package from the registry.
        #
        # e.g. get_package('hl7.fhir.us.core#3.1.1')
        #
        # @param [String] package The FHIR Package
        def get_package(package, destination, desired_types = [])
          package_url = package
            .split('#')
            .prepend(REGISTRY_SERVER_URL)
            .join('/')

          tar_file_name = "tmp/#{package.split('#').join('-')}.tgz"

          File.open(tar_file_name, 'w') do |output_file|
            output_file.binmode
            block = proc do |response|
              response.read_body do |chunk|
                output_file.write chunk
              end
            end
            RestClient::Request.execute(method: :get, url: package_url, block_response: block)
          end

          tar = Gem::Package::TarReader.new(Zlib::GzipReader.open("tmp/#{package.split('#').join('-')}.tgz"))

          path = File.join destination.split('/')
          FileUtils.mkdir_p(path)

          tar.each do |entry|
            next if entry.directory?

            next unless entry.full_name.start_with? 'package/'

            file_name = entry.full_name.split('/').last
            next if desired_types.present? && !file_name.start_with?(*desired_types)

            resource = JSON.parse(entry.read) if file_name.end_with? '.json'
            next unless resource&.[]('url')

            next if package.start_with?('us.nlm.vsac') && !REQUIRED_VSAC_VALUE_SET_URLS.include?(resource['url'])

            encoded_name = "#{encode_name(resource['url'])}.json"
            encoded_file_name = File.join(path, encoded_name)
            if File.exist?(encoded_file_name) && !resource['url'] == JSON.parse(File.read(encoded_file_name))['url']
              raise FileExistsException, "#{encoded_name} already exists for #{resource['url']}"
            end

            File.write(encoded_file_name, resource.to_json)
          end
          File.delete(tar_file_name)
        end

        def encode_name(name)
          Zlib.crc32(name)
        end
      end
    end
  end
end
