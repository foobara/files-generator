module Foobara
  module InterpolatingGenerator
    def generate(_elements_to_generate)
      start_marker = self.start_marker
      end_marker = self.end_marker

      content = "#{start_marker}#{new_content}#{end_marker}"

      if File.exist?(template_path)
        match = insert_at&.match(target_contents)

        content = if match
                    if match.captures.empty?
                      pre = match[0]
                      post = ""
                    else
                      pre, *post = match.captures
                      post = post.join
                    end

                    "#{match.pre_match}#{pre}#{content}#{post}#{match.post_match}"
                  else
                    "#{target_contents}#{content}"
                  end
      else
        match = /\A\n+/.match(content)

        # simplecov:disable
        if match
          # simplecov:enable
          newline_count = match[0].size
          start_marker = start_marker[newline_count..]
          content = match.post_match
        end

        match = /\n+\z/.match(content)

        # simplecov:disable
        if match
          # simplecov:enable
          newline_count = match[0].size
          end_marker = end_marker[...-newline_count]
          content = match.pre_match
        end

        content = "#{content}\n"
      end

      { content:, start_marker:, end_marker: }
    end

    def new_content = raise NotImplementedError
    def insert_at = nil
    def start_marker = raise NotImplementedError
    def end_marker = raise NotImplementedError
  end
end
