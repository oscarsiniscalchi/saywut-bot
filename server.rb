require 'sinatra'
require 'sinatra/namespace'
require 'mongoid'

# DB Setup
Mongoid.load! "mongoid.config"

class Quote
  include Mongoid::Document

  field :text, type: String
  field :author, type: String

  validates :text, presence: true
  validates :author, presence: true

  index({ text: 'text' })
end

namespace '/api' do
  post '/quotes' do
    command_text = params['text']
    text = command_text.match(/".*?"/)[0]
    author = command_text.match(/-\s(.*?)$/)[0]
    quote = Quote.create(text: text, author: author)

    {
      'response_type': 'ephemeral',
      'text': quote.text,
      'attachments': [
          {
              'text': "#{quote.author} / #{quote.id}"
          }
      ]
    }.to_json

  end

  post '/quotes/random' do
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
