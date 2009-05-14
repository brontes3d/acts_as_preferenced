class Preference < ActiveRecord::Base
  
  belongs_to :preferrer, :polymorphic => true
  
  serialize :value
  validates_length_of :name, :within => 1..128
  validates_uniqueness_of :name, :on => :create, :scope => [ :preferrer_id, :preferrer_type ]

end
