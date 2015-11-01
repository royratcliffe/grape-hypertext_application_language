require 'grape'

Grape::ContentTypes::CONTENT_TYPES.merge! hal_json: 'application/hal+json'
