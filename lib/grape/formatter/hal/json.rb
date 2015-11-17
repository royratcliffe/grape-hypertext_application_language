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
    #
    # Automatically converts the body to a hypertext-application-language
    # representation unless the body is already such a HAL
    # representation. Passes the Rack environment to the HAL
    # converter. Converters can use the environment to extract addressing
    # information for the representation's links, including the self link.
    #
    # Handles arrays of objects if, and only if, the elements themselves respond
    # to +to_hal+. In such cases, it replaces the array body with a HAL
    # representation conforming to a HAL collection where the collection
    # representation includes links to the elements in the collection as well as
    # embedding the nested resources. Uses the request path for the self link;
    # and uses the path, less its leading slash, as the relation.
    def self.call(body, env)
      unless body.is_a?(HypertextApplicationLanguage::Representation)
        if body.respond_to?(:first) && body.first.respond_to?(:to_hal)
          representation = HypertextApplicationLanguage::Representation.new

          rel = env['PATH_INFO'][1..-1]
          href = env['REQUEST_PATH']
          representation.with_link(HypertextApplicationLanguage::Link::SELF_REL, href)

          body.each do |resource|
            resource_representation = resource.to_hal(env: env)
            representation.with_link(rel, resource_representation.link.href)
            representation.with_representation(rel, resource_representation)
          end

          body = representation
        else
          return body unless body.respond_to?(:to_hal)
          body = body.to_hal(env: env)
        end
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
