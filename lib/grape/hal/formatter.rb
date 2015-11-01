require 'grape/formatter/hal/json'

Grape::Formatter::Base.singleton_class.const_get(:FORMATTERS).merge! hal_json: Grape::Formatter::Hal::Json
