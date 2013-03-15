module Viewpoint::EWS
  module Types

    KEY_PATHS = {}
    KEY_TYPES = {}
    KEY_ALIAS = {}

    attr_reader :ews_item

    # @param [SOAP::ExchangeWebService] ews the EWS reference
    # @param [Hash] ews_item the EWS parsed response document
    def initialize(ews, ews_item)
      @ews      = ews
      @ews_item = ews_item
      @shallow      = true
    end

    def method_missing(method_sym, *arguments, &block)
      if method_keys.include?(method_sym)
        type_convert( method_sym, resolve_method(method_sym) )
      else
        super
      end
    end

    def to_s
      "#{self.class.name}: EWS METHODS: #{self.ews_methods.sort.join(', ')}"
    end

    def shallow?
      @shallow
    end

    def auto_deepen?
      ews.auto_deepen
    end

    def deepen!
      if shallow?
        self.get_all_properties!
        @shallow = false
        true
      end
    end
    alias_method :enlighten!, :deepen!

    # @see http://www.ruby-doc.org/core/classes/Object.html#M000333
    def respond_to?(method_sym, include_private = false)
      if method_keys.include?(method_sym)
        true
      else
        super
      end
    end

    def methods(include_super = true)
      super + ews_methods
    end

    def ews_methods
      key_paths.keys + key_alias.keys
    end

    protected # things like OutOfOffice need protected level access

    def ews
      @ews
    end

    private

    def key_paths
      KEY_PATHS
    end

    def key_types
      KEY_TYPES
    end

    def key_alias
      KEY_ALIAS
    end

    def class_by_name(cname)
      if(cname.instance_of? Symbol)
        cname = cname.to_s.camel_case
      end
      Viewpoint::EWS::Types.const_get(cname)
    end

    def type_convert(key,str)
      return nil if str.nil?
      if key_types[key]
        key_types[key].is_a?(Symbol) ? method(key_types[key]).call(str) : key_types[key].call(str)
      else
        str
      end
    end

    def resolve_method(method_sym)
      begin
        resolve_key_path(@ews_item, method_path(method_sym))
      rescue
        if shallow?
          if auto_deepen?
            enlighten!
            retry
          else
            raise EwsMinimalObjectError, "Could not resolve :#{method_sym}. #auto_deepen set to false"
          end
        end
        raise
      end
    end

    def resolve_key_path(hsh, path)
      k = path.first
      return hsh[k] if hsh[k].nil? || path.length == 1
      resolve_key_path(hsh[k],path[1..-1])
    end

    def method_keys
      key_paths.keys + key_alias.keys
    end

    # Resolve the method path with or without an alias
    def method_path(sym)
      key_paths[key_alias[sym] || sym]
    end

  end
end
