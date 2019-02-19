# frozen_string_literal: true
require 'net/http'
require 'uri'

class JsonWebToken
  def self.verify(token)
    JWT.decode(token, nil,
        true, # Verify the signature of this token
        algorithm: 'RS256',                          # RS256 or HS256
        iss: 'https://YOUR_AUTH0_TENANT_DOMAIN/',    # something like 000.eu.auth0.com
        verify_iss: true,
        # aud: Rails.application.secrets.auth0_api_audience, ## <----- Notice me!
        # aud: Rails.application.credentials[Rails.env.to_sym][:auth0][:api_audience] ## With staging namespace
        aud: Rails.application.credentials[:auth0][:api_audience], ## No staging namespace
        verify_aud: true) do |header|
      jwks_hash[header['kid']]
    end
  end

  def self.jwks_hash
    jwks_raw = Net::HTTP.get URI("https://YOUR_AUTH0_TENANT_DOMAIN/.well-known/jwks.json")
    jwks_keys = Array(JSON.parse(jwks_raw)['keys'])
    Hash[
      jwks_keys
      .map do |k|
        [
          k['kid'],
          OpenSSL::X509::Certificate.new(
            Base64.decode64(k['x5c'].first)
          ).public_key
        ]
      end
    ]
  end
end