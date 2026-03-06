module AdminTools
  class SuggestDeal
    def initialize(studio:)
      @studio = studio
    end

    def call
      existing_deals = @studio.deals.where(active: true)
      suggestions = []

      inactive = count_inactive_members
      if inactive > 0
        suggestions << {
          target: "inactive_members",
          count: inactive,
          suggestion: "Come Back & Save! Offer a 30% discount on the next 5 classes to re-engage #{inactive} inactive members.",
          deal_type: "win_back"
        }
      end

      churn = count_churn_risk_members
      if churn > 0
        suggestions << {
          target: "churn_risk_members",
          count: churn,
          suggestion: "Loyalty Boost: Offer double check-in points for the next 2 weeks to #{churn} at-risk members.",
          deal_type: "retention"
        }
      end

      close = count_close_to_reward
      if close > 0
        suggestions << {
          target: "close_to_reward_members",
          count: close,
          suggestion: "Almost There! Send a nudge to #{close} members who are within 5 check-ins of earning a reward.",
          deal_type: "nudge"
        }
      end

      suggestions << {
        target: "all_members",
        suggestion: "Bring a Friend: Offer a free guest pass to boost referrals and fill low-attendance time slots.",
        deal_type: "growth"
      }

      {
        studio_name: @studio.name,
        active_deals_count: existing_deals.count,
        existing_deals: existing_deals.map { |d| { title: d.title, description: d.description } },
        suggested_deals: suggestions
      }
    end

    private

    def count_inactive_members
      cutoff = 30.days.ago
      @studio.users.where(role: "customer").count do |user|
        last = user.check_ins.where(studio: @studio).maximum(:created_at)
        last.nil? || last < cutoff
      end
    end

    def count_churn_risk_members
      cutoff = 60.days.ago
      @studio.users.where(role: "customer").count do |user|
        last = user.check_ins.where(studio: @studio).maximum(:created_at)
        last.present? && last < cutoff
      end
    end

    def count_close_to_reward
      count = 0
      @studio.rewards.each do |reward|
        count += UserReward.where(reward: reward, redeemed: false)
                           .joins(:user).where(users: { studio_id: @studio.id })
                           .select { |ur| reward.required_checkins - ur.progress <= 5 && reward.required_checkins - ur.progress > 0 }
                           .count
      end
      count
    end
  end
end
