module AdminTools
  class AdviseLoyaltyProgram
    def initialize(studio:)
      @studio = studio
    end

    def call
      customers = @studio.users.where(role: "customer")
      total_customers = customers.count
      total_checkins = CheckIn.where(studio: @studio).count
      rewards = @studio.rewards
      deals = @studio.deals

      active_last_30 = customers.select do |u|
        u.check_ins.where(studio: @studio).where("created_at > ?", 30.days.ago).exists?
      end.count
      avg_checkins_per_member = total_customers.positive? ? (total_checkins.to_f / total_customers).round(1) : 0
      retention_rate = total_customers.positive? ? ((active_last_30.to_f / total_customers) * 100).round(1) : 0

      redemption_count = UserReward.joins(:reward).where(rewards: { studio_id: @studio.id }, redeemed: true).count
      total_user_rewards = UserReward.joins(:reward).where(rewards: { studio_id: @studio.id }).count
      redemption_rate = total_user_rewards.positive? ? ((redemption_count.to_f / total_user_rewards) * 100).round(1) : 0

      advice = []

      if retention_rate < 50
        advice << "Your 30-day retention rate is #{retention_rate}%. Consider adding a streak bonus (e.g., 3 visits in one week = bonus points) to encourage habitual attendance."
      end

      if redemption_rate < 30
        advice << "Only #{redemption_rate}% of rewards have been redeemed. Your reward thresholds may be too high. Consider adding a low-tier reward (e.g., 5 check-ins) so new members see quick wins."
      end

      if rewards.count < 3
        advice << "You only have #{rewards.count} reward(s). Adding variety (e.g., merchandise, free guest passes, priority booking) increases engagement."
      end

      if deals.where(active: true).none?
        advice << "You have no active deals. Running at least one promotion at all times keeps members engaged and attracts new sign-ups."
      end

      advice << "General tip: Members who earn their first reward within 30 days are 3x more likely to stay long-term. Make sure your entry-level reward is achievable within a month of regular visits."

      {
        studio_name: @studio.name,
        metrics: {
          total_members: total_customers,
          active_last_30_days: active_last_30,
          retention_rate_30_day: "#{retention_rate}%",
          total_check_ins: total_checkins,
          avg_check_ins_per_member: avg_checkins_per_member,
          total_rewards_defined: rewards.count,
          reward_redemption_rate: "#{redemption_rate}%",
          active_deals: deals.where(active: true).count
        },
        recommendations: advice
      }
    end
  end
end
