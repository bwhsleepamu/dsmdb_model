class User < ActiveRecord::Base  
  has_many :authentications, :dependent => :delete_all
  has_and_belongs_to_many :roles
    
  # attribute methods
  attr_reader :role_tokens
  
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :rememberable, :trackable, :validatable, :timeoutable, :registerable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :role_tokens
  
  # Scopes
  scope :active, :conditions => { :active => true }
  scope :find_by_full_name, lambda {|name|
    name = '%'+name+'%'
    where("lower(first_name) like lower(?) or lower(last_name) like lower(?)", name, name)
  }
  
  # Callbacks
  before_destroy :delete_role_associations
  
  # User Methods
  
# Getter  
  def full_name  
    [first_name, last_name].join(' ')  
  end  
  
  # Setter  
  def full_name=(name)  
    split = name.split(' ', 2)  
    self.first_name = split.first  
    self.last_name = split.last  
  end 
  
  def role_tokens=(ids)
    self.role_ids = ids.split(",")
  end
  
  # Overriding Devise built-in active? method
  def active_for_authentication?
    super and self.active and not self.deleted?
  end
  
  def apply_omniauth(omniauth)
    unless omniauth['user_info'].blank?
      self.email = omniauth['user_info']['email'] if email.blank?
      self.first_name = omniauth['user_info']['first_name'] if first_name.blank?
      self.last_name = omniauth['user_info']['last_name'] if last_name.blank?
    end
    authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
  end
  
  def password_required?
    (authentications.empty? || !password.blank?) && super
  end
  
  # Declaritive Authorization - maps roles to symbols
  def role_symbols
      roles.map do |role|
        role.title.underscore.to_sym
      end
  end
  
  def json_tokens_hash
    Hash["id" => id, "name" => [full_name, '<', email, '>'].join(' ')]
  end
  
  private 
  
  # make sure association table entries are deleted before the user is deleted.  
  # this enforces oracle foreign key constraints
  def delete_role_associations
    self.roles.delete(self.roles)
  end
end
