module Mongify
  module Database
    #
    #  A representation of a sql table and how it should map to a no_sql system 
    #
    class Table
      
      attr_accessor :name, :sql_name
      attr_reader :options, :columns
      
      def initialize(sql_name, options={}, &block)
        @columns = []
        @column_lookup = {}
        @options = options.stringify_keys
        self.sql_name = sql_name
        
        self.instance_exec(&block) if block_given?
        
        import_columns
        
        self
      end
      
      def name
        @name ||= @options['rename_to']
        @name ||= self.sql_name
      end
      
      def ignored?
        @options['ignore']
      end
      
      #Add a Database Column
      def add_column(column)
        raise Mongify::DatabaseColumnExpected, "Expected a Mongify::Database::Column" unless column.is_a?(Mongify::Database::Column)
        add_and_index_column(column)
      end
      
      
      def column(name, type=nil, options={})
        options, type = type, nil if type.is_a?(Hash)
        type = type.to_sym if type
        add_and_index_column(Mongify::Database::Column.new(name, type, options))
      end
      
      def find_column(name)
        return nil unless (index = @column_lookup[name.to_s.downcase])
        @columns[index]
      end
      
      
      def reference_columns
        @columns.reject{ |c| !c.referenced? } 
      end
      
      def translate(row)
        new_row = {}
        row.each do |key, value|
          c = find_column(key)
          new_row.merge!(c.present? ? c.translate(value) : {"#{key}" => value})
        end
        new_row
      end
      
      def embed_in
        @options['embed_in'].to_s unless @options['embed_in'].nil?
      end
      
      def embed_as
        return nil unless embed?
        return 'object' if @options['as'].to_s.downcase == 'object'
        'array'
      end
      
      def embed_as_object?
        embed_as == 'object'
      end
      
      def embed?
        embed_in.present?
      end
      
      def embed_on
        return nil unless embed?
        (@options['on'] || "#{@options['embed_in'].to_s.singularize}_id").to_s
      end
            
      #######
      private
      #######
      
      def add_and_index_column(column)
        @column_lookup[column.sql_name] = @columns.size
        @columns << column
        column
      end

      def import_columns
        return unless import_columns = @options.delete('columns')
        import_columns.each { |c| add_column(c) }
      end
      
    end
  end
end