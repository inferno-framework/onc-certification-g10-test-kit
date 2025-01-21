require_relative 'authorization_request_builder'

module ONCCertificationG10TestKit
  class BulkDataAuthorization < Inferno::TestGroup
    title 'Bulk Data Authorization'
    short_description 'Demonstrate SMART Backend Services Authorization for Bulk Data.'

    id :bulk_data_authorization

    input :bulk_token_endpoint,
          title: 'Backend Services Token Endpoint',
          description: <<~DESCRIPTION
            The OAuth 2.0 Token Endpoint used by the Backend Services specification to provide bearer tokens.
          DESCRIPTION
    input :bulk_client_id,
          title: 'Bulk Data Client ID',
          description: 'Client ID provided at registration to the Inferno application.'
    input :bulk_scope,
          title: 'Bulk Data Scopes',
          description: 'Bulk Data Scopes provided at registration to the Inferno application.',
          default: 'system/*.read'
    input :bulk_encryption_method,
          title: 'Encryption Method',
          description: <<~DESCRIPTION,
            The server is required to suport either ES384 or RS384 encryption methods for JWT signature verification.
            Select which method to use.
          DESCRIPTION
          type: 'radio',
          default: 'ES384',
          options: {
            list_options: [
              {
                label: 'ES384',
                value: 'ES384'
              },
              {
                label: 'RS384',
                value: 'RS384'
              }
            ]
          }
    input :bulk_jwks_kid,
          title: 'Bulk Data JWKS kid',
          description: <<~DESCRIPTION,
            The key ID of the JWKS private key to use for signing the client assertion when fetching an auth token.
            Defaults to the first JWK in the list if no kid is supplied.
          DESCRIPTION
          optional: true
    output :bearer_token

    http_client :token_endpoint do
      url :bulk_token_endpoint
    end

    test from: :tls_version_test do
      title 'Authorization service token endpoint secured by transport layer security'
      description <<~DESCRIPTION
        [§170.315(g)(10) Test
        Procedure](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services)
        requires that all exchanges described herein between a client and a
        server SHALL be secured using Transport Layer Security (TLS) Protocol
        Version 1.2 (RFC5246).
      DESCRIPTION
      id :g10_bulk_token_tls_version

      config(
        inputs: { url: { name: :bulk_token_endpoint } },
        options: {  minimum_allowed_version: OpenSSL::SSL::TLS1_2_VERSION }
      )
    end

    test do
      title 'Authorization request fails when client supplies invalid grant_type'
      description <<~DESCRIPTION
        The Backend Service Authorization specification defines the required fields for the
        authorization request, made via HTTP POST to authorization token endpoint.
        This includes the `grant_type` parameter, where the value must be `client_credentials`.

        The OAuth 2.0 Authorization Framework describes the proper response for an
        invalid request in the client credentials grant flow:

        ```
        If the request failed client authentication or is invalid, the authorization server returns an
        error response as described in [Section 5.2](https://tools.ietf.org/html/rfc6749#section-5.2).
        ```
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/STU1.0.1/authorization/index.html#protocol-details'

      run do
        post_request_content = AuthorizationRequestBuilder.build(encryption_method: bulk_encryption_method,
                                                                 scope: bulk_scope,
                                                                 iss: bulk_client_id,
                                                                 sub: bulk_client_id,
                                                                 aud: bulk_token_endpoint,
                                                                 grant_type: 'not_a_grant_type',
                                                                 kid: bulk_jwks_kid)

        post(**{ client: :token_endpoint }.merge(post_request_content))

        assert_response_status(400)
      end
    end

    test do
      title 'Authorization request fails when supplied invalid client_assertion_type'
      description <<~DESCRIPTION
        The Backend Service Authorization specification defines the required fields for the
        authorization request, made via HTTP POST to authorization token endpoint.
        This includes the `client_assertion_type` parameter, where the value must be `urn:ietf:params:oauth:client-assertion-type:jwt-bearer`.

        The OAuth 2.0 Authorization Framework describes the proper response for an
        invalid request in the client credentials grant flow:

        ```
        If the request failed client authentication or is invalid, the authorization server returns an
        error response as described in [Section 5.2](https://tools.ietf.org/html/rfc6749#section-5.2).
        ```
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/STU1.0.1/authorization/index.html#protocol-details'

      run do
        post_request_content = AuthorizationRequestBuilder.build(encryption_method: bulk_encryption_method,
                                                                 scope: bulk_scope,
                                                                 iss: bulk_client_id,
                                                                 sub: bulk_client_id,
                                                                 aud: bulk_token_endpoint,
                                                                 client_assertion_type: 'not_an_assertion_type',
                                                                 kid: bulk_jwks_kid)

        post(**{ client: :token_endpoint }.merge(post_request_content))

        assert_response_status(400)
      end
    end

    test do
      title 'Authorization request fails when client supplies invalid JWT token'
      description <<~DESCRIPTION
        The Backend Service Authorization specification defines the required fields for the
        authorization request, made via HTTP POST to authorization token endpoint.
        This includes the `client_assertion` parameter, where the value must be
        a valid JWT. The JWT SHALL include the following claims, and SHALL be signed with the client’s private key.

        | JWT Claim | Required? | Description |
        | --- | --- | --- |
        | iss | required | Issuer of the JWT -- the client's client_id, as determined during registration with the FHIR authorization server (note that this is the same as the value for the sub claim) |
        | sub | required | The service's client_id, as determined during registration with the FHIR authorization server (note that this is the same as the value for the iss claim) |
        | aud | required | The FHIR authorization server's "token URL" (the same URL to which this authentication JWT will be posted) |
        | exp | required | Expiration time integer for this authentication JWT, expressed in seconds since the "Epoch" (1970-01-01T00:00:00Z UTC). This time SHALL be no more than five minutes in the future. |
        | jti | required | A nonce string value that uniquely identifies this authentication JWT. |

        The OAuth 2.0 Authorization Framework describes the proper response for an
        invalid request in the client credentials grant flow:

        ```
        If the request failed client authentication or is invalid, the authorization server returns an
        error response as described in [Section 5.2](https://tools.ietf.org/html/rfc6749#section-5.2).
        ```
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/STU1.0.1/authorization/index.html#protocol-details'

      run do
        post_request_content = AuthorizationRequestBuilder.build(encryption_method: bulk_encryption_method,
                                                                 scope: bulk_scope,
                                                                 iss: 'not_a_valid_iss',
                                                                 sub: bulk_client_id,
                                                                 aud: bulk_token_endpoint,
                                                                 kid: bulk_jwks_kid)

        post(**{ client: :token_endpoint }.merge(post_request_content))

        assert_response_status([400, 401])
      end
    end

    test do
      title 'Authorization request succeeds when supplied correct information'
      description <<~DESCRIPTION
        If the access token request is valid and authorized, the authorization server SHALL issue an access token in response.
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/STU1.0.1/authorization/index.html#issuing-access-tokens'

      output :authentication_response

      run do
        post_request_content = AuthorizationRequestBuilder.build(encryption_method: bulk_encryption_method,
                                                                 scope: bulk_scope,
                                                                 iss: bulk_client_id,
                                                                 sub: bulk_client_id,
                                                                 aud: bulk_token_endpoint,
                                                                 kid: bulk_jwks_kid)

        authentication_response = post(**{ client: :token_endpoint }.merge(post_request_content))

        assert_response_status([200, 201])

        output authentication_response: authentication_response.response_body
      end
    end

    test do
      title 'Authorization request response body contains required information encoded in JSON'
      description <<~DESCRIPTION
        The access token response SHALL be a JSON object with the following properties:

        | Token Property | Required? | Description |
        | --- | --- | --- |
        | access_token | required | The access token issued by the authorization server. |
        | token_type | required | Fixed value: bearer. |
        | expires_in | required | The lifetime in seconds of the access token. The recommended value is 300, for a five-minute token lifetime. |
        | scope | required | Scope of access authorized. Note that this can be different from the scopes requested by the app. |
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/STU1.0.1/authorization/index.html#issuing-access-tokens'

      input :authentication_response
      output :bearer_token

      run do
        assert_valid_json(authentication_response)
        response_body = JSON.parse(authentication_response)

        access_token = response_body['access_token']
        assert access_token.present?, 'Token response did not contain access_token as required'

        output bearer_token: access_token

        required_keys = ['token_type', 'expires_in', 'scope']

        required_keys.each do |key|
          assert response_body[key].present?, "Token response did not contain #{key} as required"
        end
      end
    end
  end
end
