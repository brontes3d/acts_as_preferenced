require File.dirname(__FILE__) + '/test_helper'

class ActsAsPreferencedTest < ActiveSupport::TestCase
  fixtures :preferences, :users

  def setup
    @user = users(:josh)
  end
  
  def test_default
    u = User.new(:login => "zinadine", :language_preference => "en_US")
    assert_equal("Chicken", u.meal_choice_preference)
    u.meal_choice_preference = "Seafood"
    assert_equal("Seafood", u.meal_choice_preference)
    u.save!
    u.reload
    assert_equal("Seafood", u.meal_choice_preference)
  end
  
  def test_set_language
    u = User.new
    u.attributes = {:login => "zinadine", :language_preference => "en_US"}
    u.save!
    u.language_preference = "German"
    assert_equal({"en_US" => "English - U.S.A.","fr_FR" => "Francais - Le France","en_FR" => "English - France"}, 
                 User.language_preference_options)
    assert_raises(ActiveRecord::RecordInvalid){
      u.save!
    }
    assert_equal("is not included in the list", u.errors.on(:language_preference))
    u.language_preference = ""
    assert_raises(ActiveRecord::RecordInvalid){
      u.save!
    }
    assert_equal("is not included in the list", u.errors.on(:language_preference))
    u.language_preference = "fr_FR"
    u.favorite_color_preference = "Beige"
    assert_raises(ActiveRecord::RecordInvalid){
      u.save!
    }
    assert_equal("is not included in the list", u.errors.on(:favorite_color_preference))
    u.favorite_color_preference = "Green"
    u.save!    
  end
  
  def test_should_not_set_preference_until_user_is_saved
    user = User.new
    user.set_preference({:language => 'en_US'})
    assert user.preferences[0].new_record?, "expected first pref to be new record but got #{user.preferences.inspect}"
    assert_raises(ActiveRecord::RecordInvalid){
      user.save!
    }
    assert user.preferences[0].new_record?, "expected first pref to be new record but got #{user.preferences.inspect}"
    user.login = "bob"
    user.save!
    assert !user.preferences[0].new_record?, "expected first pref to be saved now but got #{user.preferences.inspect}"
    user.set_preference({:complex => 'no'})
    assert user.preferences[1].new_record?, "expected second pref to be new record but got #{user.preferences.inspect}"
    user.reload
    assert_equal(1, user.preferences.size, "Expected to have only 1 pref after reload but got #{user.preferences.inspect}")
    user.set_preference({:complex => 'yes'})
    assert user.preferences[1].new_record?, "expected second pref to be new record but got #{user.preferences.inspect}"
    user.login = ""
    assert_raises(ActiveRecord::RecordInvalid){
      user.save!
    }
    assert user.preferences[1].new_record?, "expected second pref to be new record but got #{user.preferences.inspect}"
    user.reload
    assert_equal(1, user.preferences.size, "Expected to have only 1 pref after reload but got #{user.preferences.inspect}")
    user.set_preference({:complex => 'not so much'})
    user.login = "bob"
    assert user.preferences[1].new_record?, "expected second pref to be new record but got #{user.preferences.inspect}"
    user.save!
    assert !user.preferences[1].new_record?, "expected second pref to be saved now but got #{user.preferences.inspect}"
    user.set_preference({:language => 'en_FR'})
    assert user.preferences[0].changed?, "expected first pref to NOT be saved yet but got #{user.preferences.inspect}"
    user.reload
    assert_equal("en_US", user.preferences[0].value, "expected value of first pref to be reverted but got #{user.preferences.inspect}")
    user.set_preference({:language => 'en_FR'})
    user.save!
    assert !user.preferences[0].changed?, "expected first pref to be saved but got #{user.preferences.inspect}"
    user.reload
    assert_equal("en_FR", user.preferences[0].value, "expected value of first pref to be updated but got #{user.preferences.inspect}")
  end
  
  def test_blank_values_should_be_set_to_nil
    p = @user.set_preference({'simple' => ''})
    assert_nil @user.get_preference('simple')
  end
  
  def test_should_allow_symbols_and_strings_as_interchangable_identifiers
    @user.set_preference({:sym => 'test'})
    assert_equal 'test', @user.get_preference(:sym), 'did not retrieve preference with symbol identifier'
    assert_equal 'test', @user.get_preference('sym'), 'did not retrieve preference with string identifier'
    @user.set_preference({'string' => 'another'})
    assert_equal 'another', @user.get_preference(:string), 'did not retrieve preference with symbol identifier'
    assert_equal 'another', @user.get_preference('string'), 'did not retrieve preference with symbol identifier'
  end
    
  def test_should_create_preference_from_hash
    assert_difference Preference, :count do
      p = @user.set_preference({:simple => 'damn right'})
      assert p.new_record?, "#{p.errors.full_messages.to_sentence}"
      @user.save!
      assert !p.new_record?, "#{p.errors.full_messages.to_sentence}"
    end
  end

  def test_should_create_many_preferences_from_hash
    assert_difference Preference, :count, 4 do
      p = @user.set_preference({:simple => 'damn right', :easy => 'as pie', :better => 'than chocolate', :you => 'like'})
      assert_equal 4, p.length
      @user.save!
    end
  end
  
  def test_should_only_create_hash_based_preferences_one_level_deep
    assert_difference Preference, :count, 2 do
      p = @user.set_preference({:complex => {:something => {:crazy => 'nested'}}, :simple => 'test'})
      @user.save!
    end
  end
  
  def test_should_handle_nil_hashes_gracefully
    assert_no_difference Preference, :count do
      p = @user.set_preference({})
      assert_equal nil, p
    end
  end
  
  def test_should_create_a_text_based_preference
    assert_difference Preference, :count do
      p = @user.set_preference('send_me_spam',true)
      assert p.new_record?, "#{p.errors.full_messages.to_sentence}"
      @user.save!
      assert !p.new_record?, "#{p.errors.full_messages.to_sentence}"
    end
  end
    
  def test_should_create_an_association_based_preference
    assert_difference Preference, :count do
      aaron = users(:aaron)
      p = aaron.set_preference('monitor_profile_changes', true)
      assert p.new_record?, "#{p.errors.full_messages.to_sentence}"
      aaron.save!
      assert !p.new_record?, "#{p.errors.full_messages.to_sentence}"
    end
  end
  
  def test_should_allow_setting_nil_preference_values
    assert_no_difference Preference, :count do
      p = @user.set_preference('work_order_approval_notification', nil)
      assert !p.new_record?, "#{p.errors.full_messages.to_sentence}"
    end
  end
  
  def test_should_change_value_of_existing_preference
    assert_difference Preference, :count do
      aaron = users(:aaron)
      aaron.set_preference('best_guess', 'horse')
      aaron.save!
    end
    assert_no_difference Preference, :count do
      aaron = users(:aaron)
      p = aaron.set_preference('best_guess', 'unicorn')
      aaron.save!
      assert_equal 'unicorn', p.value 
    end
  end
  
  def test_should_not_overwrite_preferences_within_other_scopes
    assert_difference Preference, :count do
      @user.set_preference('scope test', 'one')
      @user.save!
    end
    assert_difference Preference, :count do
      users(:aaron).set_preference('scope test', 'three')
      users(:aaron).save!
    end
    assert_equal 'one',   @user.get_preference('scope test')
    assert_equal 'three', users(:aaron).get_preference('scope test')
  end
  
  def test_should_not_allow_duplicate_preferences_within_preferred_scope_even_when_created_directly
    assert_difference Preference, :count do
      p = Preference.create(:preferrer => users(:josh), :name => 'dupe', :value => true)
    end
    assert_no_difference Preference, :count do
      p = Preference.create(:preferrer => users(:josh), :name => 'dupe', :value => true)
      assert p.value
    end
  end
  
  def test_should_get_existing_preference_value_by_name
    assert_equal true, @user.get_preference('work_order_assignment_notification')
  end
  
  def test_should_get_existing_preference_value_by_name_and_object
    assert_equal 'weekly', users(:aaron).get_preference('watch')
  end
  
  def test_should_get_existing_preference_value_by_name_and_class
    assert_equal true, @user.get_preference('hidden')
  end
  
  def test_should_require_name
    assert_no_difference Preference, :count do
      p = users(:aaron).set_preference(nil, 'ponies')
      assert_raises(ActiveRecord::RecordInvalid){
        p.save!        
      }
      assert p.errors.on(:name), "name should have been required"
    end
  end
  
  def test_destroying_preferrer_should_destroy_associated_preferences
    cnt = @user.preferences.count
    assert_difference Preference, :count, -cnt do
      @user.destroy
    end
  end
  
  def test_should_provide_dynamic_methods_for_setting_string_preferences
    assert_difference Preference, :count do
      @user.email_notification_preference = true
      @user.save!
    end
  end
  
  def test_should_provide_dynamic_methods_for_getting_string_preferences
    assert_equal false, @user.work_order_approval_notification_preference
  end
   
end