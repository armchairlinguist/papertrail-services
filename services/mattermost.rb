# encoding: utf-8
class Service::Mattermost < Service
  def receive_logs
    raise_config_error 'Missing Mattermost URL' if settings[:mattermost_url].to_s.empty?

    display_messages = settings[:dont_display_messages].to_i != 1
    events  = payload[:events]
    message = %{"#{payload[:saved_search][:name]}" search found #{Pluralize.new('match', :count => payload[:events].length)} — <#{payload[:saved_search][:html_search_url]}|#{payload[:saved_search][:html_search_url]}>}

    data = {
      :text => message,
      :parse => 'none'
    }

    if events.present? && display_messages
      data[:attachments] = build_attachments(payload[:events])
    end

    http.headers['content-type'] = 'application/json'
    response = http_post settings[:mattermost_url], data.to_json

    unless response.success?
      puts "mattermost: #{payload[:saved_search][:id]}: #{response.status}: #{response.body}"
      raise_config_error "Could not submit logs"
    end
  end

  def build_attachments(events)
    body = build_body(events)

    [{
      :text => format_text_attachment(body),
      :mrkdwn_in => ["text"],
      :fallback => body,
    }]
  end

  def format_text_attachment(body)
    # Provide some basic escaping of ``` in messages
    body = body.gsub('```', '` ` `')

    "```" + body + "```"
  end

  # Mattermost truncates attachments at 8000 bytes
  def build_body(events, limit = 7500)
    body = ''

    events.each do |event|
      message = syslog_format(event) + "\n"
      if (body.length + message.length) < limit
        body << message
      else
        break
      end
    end

    body
  end
end
