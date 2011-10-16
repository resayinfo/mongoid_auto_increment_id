module Mongoid  
  class Identity   
    # Generate auto increment id     
    def generate_id
      counter = Mongoid.master.collection("mongoid.auto_increment_ids")
      table_name = @document.class.to_s.tableize
      o = counter.find_and_modify({:query => {:_id => table_name},
                                          :update => {:$inc => {:c => 1}}, 
                                          :new => true, 
                                          :upsert => true})
      o["c"].to_i
    end
  end
  
  module Document  
    included do
      identity :type => Integer
    end

    def identify
    end
    
    alias_method :super_as_document,:as_document
    def as_document
      result = super_as_document
      if result["_id"].blank?
        result["_id"] = Identity.new(self).generate_id
      end
      result
    end
  end
  
  module Criterion #:nodoc:
    class Unconvertable < String
      def initialize(value)
        super(value.to_s)
      end
    end
  end
  
  module Extensions #:nodoc:
    module ObjectId #:nodoc:
      # Override Mongoid::Extensions::ObjectId::Conversions.convert for covert id to Integer type.
      module Conversions
        def convert(klass, args, reject_blank = true)
          case args
          when ::Array
            args.delete_if { |arg| arg.blank? } if reject_blank
            args.replace(args.map { |arg| convert(klass, arg, reject_blank) })
          when ::Hash
            args.tap do |hash|
              hash.each_pair do |key, value|
                hash[key] = value
              end
            end
          when ::Integer
            args
          else
            return nil if not args.to_s.match(/\d+/)
            args.to_i
          end
        end
      end
    end
  end
end