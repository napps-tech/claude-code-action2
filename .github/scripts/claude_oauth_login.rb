#!/usr/bin/env ruby

require 'securerandom'
require 'uri'
require 'json'
require 'digest'
require 'base64'

class ClaudeLoginStart
  OAUTH_AUTHORIZE_URL = 'https://claude.ai/oauth/authorize'
  CLIENT_ID = '9d1c250a-e61b-44d9-88ed-5944d1962f5e'
  REDIRECT_URI = 'https://console.anthropic.com/oauth/code/callback'
  STATE_FILE = 'claude_oauth_state.json'

  def generate_login_url
    state = SecureRandom.hex(32)
    code_verifier = SecureRandom.urlsafe_base64(32)
    code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).chomp('=')
    
    # Save state and code verifier for verification later
    save_state(state, code_verifier)
    
    params = {
      'code' => 'true',
      'client_id' => CLIENT_ID,
      'response_type' => 'code',
      'redirect_uri' => REDIRECT_URI,
      'scope' => 'org:create_api_key user:profile user:inference',
      'code_challenge' => code_challenge,
      'code_challenge_method' => 'S256',
      'state' => state
    }
    
    url = "#{OAUTH_AUTHORIZE_URL}?" + URI.encode_www_form(params)
    
    puts url
    
    url
  end

  private

  def save_state(state, code_verifier)
    state_data = {
      'state' => state,
      'code_verifier' => code_verifier,
      'timestamp' => Time.now.to_i,
      'expires_at' => Time.now.to_i + 600 # 10 minutes
    }
    
    File.write(STATE_FILE, JSON.pretty_generate(state_data))
  rescue => e
    puts "Warning: Could not save state file: #{e.message}"
  end
end

if __FILE__ == $0
  if ARGV.include?('--help') || ARGV.include?('-h')
    puts "Usage: #{$0}"
    puts "  Generates an OAuth login URL for Claude Code authentication"
    puts "  --help, -h     Show this help message"
    exit 0
  end
  
  login = ClaudeLoginStart.new
  login.generate_login_url
end