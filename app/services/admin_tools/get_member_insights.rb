module AdminTools
  class GetMemberInsights
    def initialize(studio:, user_id: nil)
      @studio = studio
      @user_id = user_id
    end

    def call
      if @user_id
        single_member_insight
      else
        members_close_to_rewards
      end
    end

    private

    def single_member_insight
      user = @studio.users.find(@user_id)
      checkins = user.check_ins.where(studio: @studio)
      user_rewards = user.user_rewards.includes(:reward).where(rewards: { studio_id: @studio.id })

      {
        member: {
          id: user.id,
          name: "#{user.first_name} #{user.last_name}",
          email: user.email,
          total_check_ins: checkins.count,
          first_check_in: checkins.minimum(:created_at)&.strftime("%Y-%m-%d"),
          last_check_in: checkins.maximum(:created_at)&.strftime("%Y-%m-%d"),
          days_since_last_visit: checkins.maximum(:created_at) ? ((Time.current - checkins.maximum(:created_at)) / 1.day).round : nil,
          rewards: user_rewards.map do |ur|
            {
              reward_name: ur.reward.name,
              progress: ur.progress,
              required: ur.reward.required_checkins,
              remaining: [ur.reward.required_checkins - ur.progress, 0].max,
              redeemed: ur.redeemed
            }
          end,
          checkin_trend: monthly_checkin_trend(checkins)
        }
      }
    end

    def members_close_to_rewards
      rewards = @studio.rewards
      close_members = []

      rewards.each do |reward|
        UserReward.where(reward: reward, redeemed: false).includes(:user).each do |ur|
          next unless ur.user.studio_id == @studio.id

          remaining = reward.required_checkins - ur.progress
          percentage = (ur.progress.to_f / reward.required_checkins * 100).round

          next unless remaining.positive? && remaining <= 5

          close_members << {
            user_id: ur.user.id,
            name: "#{ur.user.first_name} #{ur.user.last_name}",
            reward_name: reward.name,
            progress: ur.progress,
            required: reward.required_checkins,
            remaining: remaining,
            percentage: percentage
          }
        end
      end

      close_members.sort_by! { |m| m[:remaining] }

      {
        studio_name: @studio.name,
        members_close_to_rewards: close_members.size,
        members: close_members
      }
    end

    def monthly_checkin_trend(checkins)
      (0..5).map do |months_ago|
        month_start = months_ago.months.ago.beginning_of_month
        month_end = months_ago.months.ago.end_of_month
        {
          month: month_start.strftime("%B %Y"),
          count: checkins.where(created_at: month_start..month_end).count
        }
      end.reverse
    end
  end
end
