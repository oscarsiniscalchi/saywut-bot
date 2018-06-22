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

    text   = command_text.match(/(^.*?)-/).try(:[], 1)
    author = command_text.match(/-\s?(.*?)$/).try(:[], 1)

    return Errors.invalid_text unless text && author

    quote = Quote.create(text: text, author: author)

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
