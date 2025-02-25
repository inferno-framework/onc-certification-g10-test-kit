require 'smart_app_launch/standalone_launch_group'
require 'smart_app_launch/discovery_stu1_group'
require 'smart_app_launch/token_introspection_group'

require_relative 'g10_options'

module ONCCertificationG10TestKit
  class TokenIntrospectionGroup < SMARTAppLaunch::SMARTTokenIntrospectionGroup
    id :g10_token_introspection

    description <<~DESCRIPTION

      This scenario verifies the ability of an authorization server to
      perform token introspection in accordance with the [SMART App Launch STU2
      Implementation Guide Section on Token
      Introspection](https://hl7.org/fhir/smart-app-launch/STU2/token-introspection.html).
      Inferno first acts as a registered SMART App Launch client to request and
      receive a valid access token, and then as an authorized resource server that
      queries the authorization server for information about this access token.

      The system under test must perform the following in order to pass this
      scenario:
      * Issue a new bearer token to Inferno acting as a registered SMART App
        Launch client.  The tester has flexibility in deciding what type of SMART
        App Launch client is used (e.g. public or confidential).  This is
        redundant to tests earlier in this test suite, but is performed to ensure
        an active token can be introspected.
      * Respond to a token introspection request from Inferno acting as a
        resource server for both valid and invalid tokens.  Systems have flexibility
        in how access control for this service is implemented.  To account for
        this flexibility, the tester has the ability to add an Authorization
        Header to the request (provided out-of-band of these tests), as well as
        additional Introspect parameters, as allowed by the specification.

    DESCRIPTION

    input_instructions <<~INSTRUCTIONS
      If the introspection endpoint is access controlled, testers must enter their own
      HTTP Authorization header for the introspection request. See [RFC 7616 The
      'Basic' HTTP Authentication
      Scheme](https://datatracker.ietf.org/doc/html/rfc7617) for the most common
      approach that uses client credentials. Testers may also provide any
      additional parameters needed for their authorization server to complete
      the introspection request.

      **Note:** For both the Authorization header and request parameters, user-input
      values will be sent exactly as entered and therefore the tester must
      URI-encode any appropriate values.
    INSTRUCTIONS

    run_as_group

    input :well_known_introspection_url,
          title: 'Token Introspection Endpoint',
          description: <<~DESCRIPTION,
            The complete URL of the token introspection endpoint. This will be
            populated automatically if included in the server's discovery
            endpoint.
          DESCRIPTION
          optional: true

    input_order :url,
                :well_known_introspection_url,
                :custom_authorization_header,
                :optional_introspection_request_params,
                :standalone_smart_auth_info

    config(
      inputs: {
        smart_auth_info: {
          name: :standalone_smart_auth_info,
          title: 'Standalone Launch Credentials',
          options: {
            components: [
              {
                name: :jwks,
                locked: true
              }
            ]
          }
        }
      }
    )

    groups.first.description <<~DESCRIPTION
      These tests are perform discovery and a standalone launch in order to
      receive a new, active access token that will be provided for token
      introspection.
    DESCRIPTION

    groups[1].description <<~DESCRIPTION
      This group of tests executes the token introspection requests and ensures
      the correct HTTP response is returned but does not validate the contents
      of the token introspection response.
    DESCRIPTION
  end
end
