class Authentication < ActiveRecord::Base
  belongs_to :user

  def provider_name
    CUSTOM_LOGGER.info "WELL GETS TO PROVIDER NAME"
    OmniAuth.config.camelizations[provider.to_s.downcase] || provider.to_s.titleize
  end
end
