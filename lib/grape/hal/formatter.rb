require 'grape/formatter/hal/json'

Grape::Formatter.register :hal_json, Grape::Formatter::Hal::Json
