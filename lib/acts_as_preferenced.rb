module ActsAsPreferenced
  
  PREFERENCE_REGEX = /(\w+)_preference([=]?)$/

  def self.included(base) # :nodoc:
     base.extend ClassMethods
  end
  
  module ClassMethods
    def acts_as_preferenced(options = {})
      # don't allow multiple calls
      return if self.included_modules.include?(ActsAsPreferenced::InstanceMethods)
      
      # associated preferences
      has_many :preferences, :dependent => :destroy, :as => :preferrer, :autosave => true

      # and finally our lovely instance methods
      include ActsAsPreferenced::InstanceMethods

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
        pref = Preference.new(:name => name, :value => value)
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
