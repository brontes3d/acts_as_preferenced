class Preference < ActiveRecord::Base  
  is_preference_model
  
  preference_for(User) do
    language(:options => {"en_US" => "English - U.S.A.",
          "fr_FR" => "Francais - Le France",
          "en_FR" => "English - France"})
    favorite_color(:options => ["Red","Green","Blue"], :allow_nil => true)
  end
  
end
