module AdminTools
  class AnalyzeChurnRisk
    RISK_LEVELS = { high: 60, medium: 30, low: 14 }.freeze

    def initialize(studio:)
      @studio = studio
    end

    def call
      customers = @studio.users.where(role: "customer")

      risk_analysis = customers.map do |user|
        checkins = user.check_ins.where(studio: @studio)
        last_checkin = checkins.maximum(:created_at)
        total = checkins.count
        days_absent = last_checkin ? ((Time.current - last_checkin) / 1.day).round : 999

        frequency = if total > 1
                      first_checkin = checkins.minimum(:created_at)
                      span_days = ((last_checkin - first_checkin) / 1.day).round
                      span_days > 0 ? (span_days.to_f / total).round(1) : 0
                    else
                      0
                    end

        risk_level = if days_absent >= RISK_LEVELS[:high]
                       "high"
                     elsif days_absent >= RISK_LEVELS[:medium]
                       "medium"
                     elsif days_absent >= RISK_LEVELS[:low]
                       "low"
                     else
                       "none"
                     end

        {
          id: user.id,
          name: "#{user.first_name} #{user.last_name}",
          risk_level: risk_level,
          days_since_last_visit: days_absent,
          total_check_ins: total,
          avg_days_between_visits: frequency,
          last_check_in: last_checkin&.strftime("%Y-%m-%d") || "Never"
        }
      end

      risk_order = { "high" => 0, "medium" => 1, "low" => 2, "none" => 3 }
      risk_analysis.sort_by! { |m| risk_order[m[:risk_level]] }

      {
        studio_name: @studio.name,
        total_customers: customers.count,
        high_risk: risk_analysis.count { |m| m[:risk_level] == "high" },
        medium_risk: risk_analysis.count { |m| m[:risk_level] == "medium" },
        low_risk: risk_analysis.count { |m| m[:risk_level] == "low" },
        members: risk_analysis
      }
    end
  end
end
