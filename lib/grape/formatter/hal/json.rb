require 'grape'
require 'hypertext_application_language'
require 'addressable/uri'
require 'json'

module Grape::Formatter::Hal
  class Json
    # Formats a Grape end-point body using JSON-formatted hypertext application
    # language. Assumes that the body is a hypertext-application-language
    # representation, either a resource or collection of resources.
    #
    # Derives the end-point's request URL using only the plain Rack environment
    # if necessary; doing so assumes nothing about any higher-level framework,
    # e.g. Grape or Sinatra. Uses the base URL to adjust all the relative
    # hypertext references. They become absolute references; meaning not
    # relative, i.e. the reference does not include a scheme. Applies this
    # adjustment to the representation itself as well as all the embedded
    # representations if any.
    def self.call(body, env)
      unless body.is_a?(HypertextApplicationLanguage::Representation)
        return body unless body.respond_to?(:to_hal)
        body = body.to_hal
      end

      endpoint = env['api.endpoint']
      request = endpoint ? endpoint.request : Rack::Request.new(env)
      base_uri = Addressable::URI.parse(request.base_url + request.script_name + '/')

      representations = [body] + body.representations
      representations.map(&:links).flatten.each do |link|
        uri = Addressable::URI.parse(link.href)
        link.href = base_uri.join(uri).to_s unless uri.absolute?
      end

      renderer = HypertextApplicationLanguage::HashRepresentationRenderer.new
      JSON.pretty_generate(renderer.render(body))
    end
  end
end
