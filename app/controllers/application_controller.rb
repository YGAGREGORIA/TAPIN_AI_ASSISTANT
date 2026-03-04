class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # After sign-in, send users to the customer dashboard
  def after_sign_in_path_for(_resource)
    customer_dashboard_path
  end
end
