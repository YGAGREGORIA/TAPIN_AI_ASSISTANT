module Customer
  class DashboardsController < ApplicationController
    before_action :authenticate_user!

    def show
      @user = current_user
      @studio = current_user.studios
      @recent_check_ins = current_user.check_ins.includes(:studio).order(created_at: :desc).limit(10)
      @total_check_ins = current_user.check_ins.count
      @user_rewards = current_user.user_rewards.includes(:reward)
      @tier = determine_tier(@total_check_ins)
    end

    private

    def determine_tier(checkin_count)
      case checkin_count
      when 0..9 then "Member"
      when 10..24 then "Bronze"
      when 25..49 then "Silver"
      else "Gold"
      end
    end
  end
end
