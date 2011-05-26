class Study < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  
  # Attributes
  attr_accessor :pl_tokens, :pi_tokens 
  attr_accessible :nickname, :new_irb_attributes, :deleted_irb_ids, :pl_tokens, :pi_tokens
  
  # Associations
  has_and_belongs_to_many :irbs
  has_many :subjects
  has_many :personnel_roles, :dependent => :destroy
  has_many :personnel, :through => :personnel_roles
  has_many :events
  
  
  # Scopes

  # Callbacks
  after_update :save_irbs
  before_save :save_personnel
  before_destroy :delete_personnel_associations, :delete_irb_associations
  
  # Getters
  def pis
    personnel.find(:all, :include => :personnel_roles, :conditions => "role_name = 'PI'")
  end
  
  def pls
    personnel.find(:all, :include => :personnel_roles, :conditions => "role_name = 'PL'")
  end
  
  # Setters
  def new_irb_attributes=(irb_attributes)
    # Either find existing Irb object or create new one, then add to study
    irb_attributes.each do |attr|
      unless (attr[:protocol_id].empty? || attr[:protocol_id].nil?)
        new_irb = Irb.find_or_create_by_protocol_id(attr[:protocol_id]) 
        irbs << new_irb unless irbs.include?(new_irb)
      end
    end
  end
  
  def deleted_irb_ids=(irb_ids)
    irb_ids = irb_ids.map(&:to_i)
    irbs_to_delete = irbs.find_all_by_irb_id(irb_ids)
    irbs.delete(irbs_to_delete)
  end
  
  # Helpers
  def save_personnel
    # adds personnel with their proper roles (either PI or PL) to the study using tokeninput
    personnel.clear
    personnel_roles.clear
    
    CUSTOM_LOGGER.info pi_tokens
    CUSTOM_LOGGER.info pl_tokens
    
    
    pi_ids = pi_tokens.split(',')
    pl_ids = pl_tokens.split(',')
    ids_roles = pi_ids.map{|pi| Hash[:id => pi, :role => "PI"]}
    ids_roles.concat( pl_ids.map{|pi| Hash[:id => pi, :role => "PL"]}) 
    
    CUSTOM_LOGGER.info ids_roles
    ids_roles.each do |ir|
      personnel_roles.build(:personnel_id => ir[:id], :role_name => ir[:role]) 
    end
  end
  
  def save_irbs
    irbs.each do |irb|
      irb.save(false)
    end
  end
  
  
  # make sure association table entries are deleted before the user is deleted.  
  # this enforces oracle foreign key constraints
  def delete_personnel_associations
    self.personnel.delete(self.personnel)
  end
  def delete_irb_associations
    self.irbs.delete(self.irbs)
  end
  
end
