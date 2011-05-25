class Study < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  
  # Attributes
  attr_reader :personnel_tokens  
  attr_accessible :nickname, :personnel_tokens, :new_irb_attributes, :deleted_irb_ids
  
  # Associations
  has_and_belongs_to_many :irbs
  has_many :subjects
  has_many :personnel_roles, :dependent => :destroy
  has_many :personnel, :through => :personnel_roles
  has_many :events
  
  # Callbacks
  after_update :save_irbs
  def personnel_tokens=(ids)
    self.personnel_ids = ids.split(",")
  end
  
  # Setters
  def new_irb_attributes=(irb_attributes)
    # Either find existing Irb object or create new one, then add to study
    irb_attributes.each do |attr|
      new_irb = Irb.find_or_create_by_protocol_id(attr[:protocol_id]) unless (attr[:protocol_id].empty? || attr[:protocol_id].nil?)
      irbs << new_irb unless irbs.include?(new_irb)
    end
  end
  
  def deleted_irb_ids=(irb_ids)
    irb_ids = irb_ids.map(&:to_i)
    irbs_to_delete = irbs.find_all_by_irb_id(irb_ids)
    irbs.delete(irbs_to_delete)
  end
  
  def save_irbs
    irbs.each do |irb|
      irb.save(false)
    end
  end
end
