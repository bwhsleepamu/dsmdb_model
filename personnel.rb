class Personnel < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :first_name, :last_name


  ##
  # Associations
  has_many :studies, :foreign_key => "pi_id"
  has_many :subjects, :foreign_key => "pl_id"

  ##
  # Validations
  validates_presence_of :first_name, :last_name
  validates_uniqueness_of :first_name, :scope => :last_name, :message => "Not a unique name"

  ##
  # Scopes
  scope :find_by_full_name, lambda {|name|
    name = '%'+name+'%'
    where("lower(first_name) like lower(?) or lower(last_name) like lower(?)", name, name)
  }
  
  ##
  # Getter
  def full_name  
    [first_name, last_name].join(' ')  
  end  
  
  ##
  # Setter
  def full_name=(name)  
    split = name.split(' ', 2)  
    self.first_name = split.first  
    self.last_name = split.last  
  end
   
  # Helper functions
  def json_tokens_hash
    Hash["id" => personnel_id, "name" => full_name]
  end
end
