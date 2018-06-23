require 'sinatra'
require 'sinatra/namespace'
require 'mongoid'
require 'json'

# DB Setup
Mongoid.load! "mongoid.yml"

class Quote
  include Mongoid::Document

  field :text, type: String
  field :author, type: String

  validates :text, presence: true
  validates :author, presence: true

  index({ text: 'text' })
end

module Errors
  def self.empty_text
    {
      'response_type': 'ephemeral',
      'text': 'Please provide a quote and author'
    }.to_json
  end

  def self.invalid_text
    {
      'response_type': 'ephemeral',
      'text': 'Invalid format use "SOME QUOTE" - @AUTHOR'
    }.to_json
  end
end

namespace '/api' do
  post '/quotes' do
    content_type :json
    command_text = params['text'] or return Errors.empty_text

    regex = /(.*?)-(?!.*-)(.*?$)/
    data   = command_text.match(regex)
    return Errors.invalid_text unless data && data[1] && data[2]
    text   = data[1]
    author = data[2]

    quote = Quote.create(text: text, author: author)

    return Errors.empty_text unless quote.valid?

    {
      'response_type': 'in_channel',
      'text': quote.text,
      'attachments': [{ 'text': "#{quote.author}" }]
    }.to_json

  end

  post '/quotes/last' do
    content_type :json
    quote = Quote.last

    {
      'response_type': 'in_channel',
      'text': quote.text,
      'attachments': [
          {
              'text': quote.author
          }
      ]
    }.to_json
  end

  post '/quotes/random' do
    content_type :json
    quote = Quote.all.sample

    {
      'response_type': 'in_channel',
      'text': quote.text,
      'attachments': [
          {
              'text': quote.author
          }
      ]
    }.to_json
  end
end
