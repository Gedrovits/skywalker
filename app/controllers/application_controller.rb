class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  def proof_of_concept
  end

  before_action :set_locale

  def set_locale
    I18n.locale = params[:hl]&.to_sym || I18n.default_locale
  end
end
