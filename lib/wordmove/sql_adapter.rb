module Wordmove
  class SqlAdapter
    attr_accessor :sql_content
    attr_reader :sql_path, :source_config, :dest_config

    def initialize(sql_path, source_config, dest_config)
      @sql_path = sql_path
      @source_config = source_config
      @dest_config = dest_config
    end

    def sql_content
      @sql_content ||= File.open(sql_path).read
    end

    def adapt!
      replace_vhost!
      replace_wordpress_path!
      replace_extra_fields!
      write_sql!
    end

    def replace_extra_fields!
      source_extra_fields = source_config[:extra_fields]
      dest_extra_fields = dest_config[:extra_fields]
      if source_extra_fields.keys == dest_extra_fields.keys
        source_extra_fields.values.zip(dest_extra_fields.values).each do |source, dest|
          replace_field!(source, dest)
        end
      end
    end

    def replace_vhost!
      source_vhost = source_config[:vhost]
      dest_vhost = dest_config[:vhost]
      replace_field!(source_vhost, dest_vhost)
    end

    def replace_wordpress_path!
      source_path = source_config[:wordpress_absolute_path] || source_config[:wordpress_path]
      dest_path = dest_config[:wordpress_absolute_path] || dest_config[:wordpress_path]
      replace_field!(source_path, dest_path)
    end

    def replace_field!(source_field, dest_field)
      if source_field && dest_field
        serialized_replace!(source_field, dest_field)
        simple_replace!(source_field, dest_field)
      end
    end

    def serialized_replace!(source_field, dest_field)
      length_delta = source_field.length - dest_field.length

      sql_content.gsub!(/s:(\d+):([\\]*['"])(.*?)\2;/) do |_|
        length = Regexp.last_match(1).to_i
        delimiter = Regexp.last_match(2)
        string = Regexp.last_match(3)

        string.gsub!(/#{Regexp.escape(source_field)}/) do |_|
          length -= length_delta
          dest_field
        end

        %(s:#{length}:#{delimiter}#{string}#{delimiter};)
      end
    end

    def simple_replace!(source_field, dest_field)
      sql_content.gsub!(source_field, dest_field)
    end

    def write_sql!
      File.open(sql_path, 'w') { |f| f.write(sql_content) }
    end
  end
end
