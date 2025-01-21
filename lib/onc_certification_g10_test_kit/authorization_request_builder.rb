require 'json/jwt'

module ONCCertificationG10TestKit
  class AuthorizationRequestBuilder
    def self.build(...)
      new(...).authorization_request
    end

    def self.bulk_data_jwks
      @bulk_data_jwks ||= JSON.parse(File.read(ENV.fetch('G10_BULK_DATA_JWKS',
                                                         File.join(__dir__, 'bulk_data_jwks.json'))))
    end

    attr_reader :encryption_method, :scope, :iss, :sub, :aud, :content_type, :grant_type, :client_assertion_type, :exp,
                :jti, :kid

    def initialize(
      encryption_method:,
      scope:,
      iss:,
      sub:,
      aud:,
      content_type: 'application/x-www-form-urlencoded',
      grant_type: 'client_credentials',
      client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      exp: 5.minutes.from_now,
      jti: SecureRandom.hex(32),
      kid: nil
    )
      @encryption_method = encryption_method
      @scope = scope
      @iss = iss
      @sub = sub
      @aud = aud
      @content_type = content_type
      @grant_type = grant_type
      @client_assertion_type = client_assertion_type
      @exp = exp
      @jti = jti
      @kid = kid
    end

    def bulk_private_key
      @bulk_private_key ||=
        self.class.bulk_data_jwks['keys']
          .select { |key| key['key_ops']&.include?('sign') }
          .select { |key| key['alg'] == encryption_method }
          .find { |key| !kid || key['kid'] == kid }
    end

    def jwt_token
      @jwt_token ||= JSON::JWT.new(iss:, sub:, aud:, exp:, jti:).compact
    end

    def jwk
      @jwk ||= JSON::JWK.new(bulk_private_key)
    end

    def authorization_request_headers
      {
        content_type:,
        accept: 'application/json'
      }.compact
    end

    def authorization_request_query_values
      {
        'scope' => scope,
        'grant_type' => grant_type,
        'client_assertion_type' => client_assertion_type,
        'client_assertion' => client_assertion.to_s
      }.compact
    end

    def client_assertion
      @client_assertion ||=
        begin
          jwt_token.kid = jwk['kid']
          jwk_private_key = jwk.to_key
          jwt_token.sign(jwk_private_key, bulk_private_key['alg'])
        end
    end

    def authorization_request
      uri = Addressable::URI.new
      uri.query_values = authorization_request_query_values

      { body: uri.query, headers: authorization_request_headers }
    end
  end
end
