class CreateSharedExtensionsSchema < ActiveRecord::Migration[6.0]
  def up
    create_schema(extensions_schema) unless schema_exists?(extensions_schema)

    %w[unaccent pg_trgm].each do |extension|
      if extension_enabled?(extension)
        unless extension_already_in_extensions_schema?(extension)
          execute_or_log_warning("ALTER EXTENSION #{extension} SET SCHEMA #{extensions_schema}")
        end
      else
        execute_or_log_warning("CREATE EXTENSION #{extension} SCHEMA #{extensions_schema}")
      end
    end

    execute "GRANT usage ON SCHEMA #{extensions_schema} TO public"
  end

  def down
    %w[unaccent pg_trgm].each do |extension|
      execute "ALTER EXTENSION #{extension} SET SCHEMA public;"
    end

    execute "DROP SCHEMA #{extensions_schema};"
  end

  private

    def extensions_schema
      "shared_extensions"
    end

    def extension_already_in_extensions_schema?(extension)
      schema_id_for(extension) == extensions_schema_id
    end

    def schema_id_for(extension)
      query_value("SELECT extnamespace FROM pg_extension WHERE extname=#{quote(extension)}")
    end

    def extensions_schema_id
      query_value("SELECT oid FROM pg_namespace WHERE nspname=#{quote(extensions_schema)}")
    end

    def execute_or_log_warning(statement)
      if superuser?
        execute statement
      else
        log_warning(statement)
      end
    end

    def superuser?
      query_value("SELECT usesuper FROM pg_user where usename = CURRENT_USER")
    end

    def log_warning(statement)
      message = "If you'd like to enable the multitenancy feature, manually run " +
                "#{statement}; using a user with enough database privileges."

      Rails.logger.warn(message)
      ApplicationLogger.new.logger.warn(message)
    end
end
