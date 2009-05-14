class Preference < ActiveRecord::Base  
  is_preference_model
  
  preference_for(User) do
    language
    # language(:options => ["English", "French"])
  end
  
end
