module Customer
  class DashboardsController < ApplicationController
    before_action :authenticate_user!

    def show
      @user = current_user
      @studio = current_user.studio

      # Check-ins
      @recent_check_ins = current_user.check_ins
        .includes(:studio)
        .order(created_at: :desc)
        .limit(10)

      @total_check_ins = current_user.check_ins.count

      @check_ins_this_month = current_user.check_ins
        .where(created_at: Time.current.beginning_of_month..Time.current)
        .count

      # Rewards
      @user_rewards = current_user.user_rewards.includes(:reward)

      @available_rewards = @user_rewards.select do |ur|
        ur.progress >= ur.reward.required_checkins && !ur.redeemed
      end

      # Tier system
      @tier = determine_tier(@total_check_ins)
      @next_tier_goal = next_tier_goal(@total_check_ins)

      @progress_to_next_tier =
        (@total_check_ins.to_f / @next_tier_goal * 100).round

      # Favorite studio
      @favorite_studio = current_user.check_ins
        .joins(:studio)
        .group("studios.name")
        .order("count_all DESC")
        .count
        .first&.first

      # Streak
      @current_streak = calculate_streak
    end

    private

    def determine_tier(checkin_count)
      case checkin_count
      when 0..9
        "Member"
      when 10..24
        "Bronze"
      when 25..49
        "Silver"
      else
        "Gold"
      end
    end

    def next_tier_goal(checkins)
      case checkins
      when 0..9
        10
      when 10..24
        25
      when 25..49
        50
      else
        50
      end
    end

    def calculate_streak
      dates = current_user.check_ins
        .order(created_at: :desc)
        .pluck(:created_at)
        .map(&:to_date)
        .uniq

      streak = 0
      today = Date.current

      dates.each do |date|
        break unless date == today - streak
        streak += 1
      end

      streak
    end
  end
end
