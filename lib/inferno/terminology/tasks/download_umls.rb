require 'nokogiri'
require 'rest-client'
require_relative 'temp_dir'

module Inferno
  module Terminology
    module Tasks
      class DownloadUMLS
        include TempDir

        UMLS_FILE_URLS = {
          '2019' => 'https://download.nlm.nih.gov/umls/kss/2019AB/umls-2019AB-full.zip',
          '2020' => 'https://download.nlm.nih.gov/umls/kss/2020AB/umls-2020AB-full.zip',
          '2021' => 'https://download.nlm.nih.gov/umls/kss/2021AA/umls-2021AA-full.zip',
          '2022' => 'https://download.nlm.nih.gov/umls/kss/2022AA/umls-2022AA-full.zip',
          '2023' => 'https://download.nlm.nih.gov/umls/kss/2023AA/umls-2023AA-full.zip'
        }.freeze
        TICKET_GRANTING_TICKET_URL = 'https://utslogin.nlm.nih.gov/cas/v1/api-key'.freeze

        attr_reader :version, :api_key

        def initialize(version:, apikey:)
          @version = version
          @api_key = apikey
        end

        def run
          # Adapted from https://documentation.uts.nlm.nih.gov/automating-downloads.html

          FileUtils.mkdir_p(versioned_temp_dir)

          target_file = UMLS_FILE_URLS[version]

          Inferno.logger.info 'Getting Ticket Granting Ticket'
          ticket_granting_ticket_html = RestClient::Request.execute(
            method: :post,
            url: TICKET_GRANTING_TICKET_URL,
            payload: {
              apikey: api_key
            }
          )
          ticket_granting_ticket =
            Nokogiri::HTML(ticket_granting_ticket_html.body).at_css('form').attributes['action'].value

          Inferno.logger.info 'Getting ticket'
          ticket = RestClient::Request.execute(
            method: :post,
            url: ticket_granting_ticket,
            payload: {
              service: target_file
            }
          ).body

          begin
            Inferno.logger.info 'Downloading'
            RestClient::Request.execute(
              method: :get,
              url: "#{target_file}?ticket=#{ticket}",
              max_redirects: 0
            )
          rescue RestClient::ExceptionWithResponse => e
            ticket = RestClient::Request.execute(
              method: :post,
              url: ticket_granting_ticket,
              payload: {
                service: e.response.headers[:location]
              }
            ).body
            target_location = umls_zip_path
            follow_redirect(e.response.headers[:location], target_location, ticket, e.response.headers[:set_cookie])
          end
          Inferno.logger.info 'Finished Downloading!'
        end

        def follow_redirect(location, file_location, ticket, cookie = nil)
          return unless location

          size = 0
          percent = 0
          current_percent = 0
          File.open(file_location, 'w') do |f|
            f.binmode
            block = proc do |response|
              Inferno.logger.info response.header['content-type']
              if response.header['content-type'] == 'application/zip'
                total = response.header['content-length'].to_i
                response.read_body do |chunk|
                  f.write chunk
                  size += chunk.size
                  percent = ((size * 100) / total).round unless total.zero?
                  if current_percent != percent
                    current_percent = percent
                    Inferno.logger.info "#{percent}% complete"
                  end
                end
              else
                follow_redirect(response.header['location'], file_location, ticket, response.header['set-cookie'])
              end
            end
            RestClient::Request.execute(
              method: :get,
              url: "#{location}?ticket=#{ticket}",
              headers: { cookie: },
              block_response: block
            )
          end
        end
      end
    end
  end
end
