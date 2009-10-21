module ActsAsPreferenced
  
  PREFERENCE_REGEX = /(\w+)_preference([=]?)$/
  
  def self.included(base) # :nodoc:
     base.extend ClassMethods
  end
  
  module ClassMethods
    def is_preference_model
      belongs_to :preferrer, :polymorphic => true

      serialize :value
      validates_length_of :name, :within => 1..128
      validates_uniqueness_of :name, :on => :create, :scope => [ :preferrer_id, :preferrer_type ]
      
      extend ActsAsPreferenced::IsPreferenceClassMethods
      
    end
    def acts_as_preferenced(options = {})
      # don't allow multiple calls
      return if self.included_modules.include?(ActsAsPreferenced::InstanceMethods)
      
      # associated preferences
      has_many :preferences, :dependent => :destroy, :as => :preferrer, :autosave => true

      # and finally our lovely instance methods
      include ActsAsPreferenced::InstanceMethods
      Preference rescue nil
    end
  end
  
  module IsPreferenceClassMethods
    
    class PreferenceDefiner
      class H
        def self.add_method(to_model, method_name, &block)
          to_model.class_eval{ define_method(method_name, &block) }
        end
        def self.add_class_method(to_model, method_name, &block)
          to_model.class_eval{ class << self; self end }.send(:define_method, method_name, &block)
        end
      end
      
      def initialize(for_model)
        @for_model = for_model
      end
      def method_missing(symbol, *args)
        H.add_method(@for_model, "#{symbol}_preference") do
          get_preference(symbol)
        end
        H.add_method(@for_model, "#{symbol}_preference=") do |value|
          set_preference(symbol, value)
        end
        H.add_class_method(@for_model, "find_all_by_#{symbol}_preference") do |value|
          find(:all, :include => ['preferences'],
                     :conditions => ["preferences.name = ? AND preferences.value = ?", symbol.to_s, value])
        end
        if opts = args[0]
          if default_choice = opts[:default]
            H.add_method(@for_model, "#{symbol}_preference") do
              get_preference(symbol) || default_choice
            end
          end
          if options = opts[:options]
            H.add_class_method(@for_model, "#{symbol}_preference_options"){ options }
            options_to_validation = {}
            options_to_validation[:in] = @for_model.send("#{symbol}_preference_options")
            if opts[:allow_nil] || opts[:default]
              options_to_validation[:allow_nil] = true
            end
            @for_model.class_eval do
              validates_inclusion_of "#{symbol}_preference", options_to_validation
            end
          elsif opts[:allow_nil] == false
            @for_model.class_eval do
              validates_presence_of "#{symbol}_preference"
            end
          end
        end
      end
    end
    
    def preference_for(*models, &block)
      models.each do |model|
        unless model.included_modules.include?(ActsAsPreferenced::InstanceMethods)
          raise ArgumentError, "Can't define structure of preferences for #{model} because it does not 'acts_as_preferenced' "
        end
        PreferenceDefiner.new(model).instance_eval(&block)
      end
    end
    
  end
  
  module InstanceMethods
    
    # Set a preference within the context of this user
    # obj can be an object or class and name must be a string
    # you may additionally pass a hash to create several preferences at once
    def set_preference(name, value=nil)
      value = nil if value.blank?
      if name.is_a? Hash
        pref, prefs = nil, []
        name.keys.each{|key| prefs << pref = self.set_preference(key.to_s, name[key]) } and return prefs.size > 1 ? prefs : pref
      end
      if pref = self.preferences.detect{|p| p.name == name.to_s }
        pref.value = value
      else
        pref = Preference.new(:name => name.to_s, :value => value)
        self.preferences.target << pref
      end
      pref
    end
  
    # Returns selected preference value
    def get_preference(name)
      (x = self.preferences.detect{|p| p.name == name.to_s }).nil? ? nil : x.value
    end
  
  protected

    # check for dynamic preference methods
    def method_missing(symbol, *args)
      if symbol.to_s =~ PREFERENCE_REGEX
        process_preference_request(symbol, args)
      else
        super
      end
    end
  
    # either sets or returns the preference based on the request
    def process_preference_request(symbol, *args)
      args.flatten!
      name = symbol.to_s.gsub(PREFERENCE_REGEX,'\\1\\2')
      if name =~ /=$/
        raise ArgumentError.new("wrong number of arguments (#{args.size} for 1)") if args.size != 1
        set_preference(name.gsub(/=$/,''), args[0])
      else
        raise ArgumentError.new("wrong number of arguments (#{args.size} for 0)") if args.size != 0
        get_preference(name)
      end
    end

  end  
end
