module AdminTools
  class GetInactiveMembers
    INACTIVE_THRESHOLD_DAYS = 30

    def initialize(studio:, days_threshold: INACTIVE_THRESHOLD_DAYS)
      @studio = studio
      @days_threshold = days_threshold
    end

    def call
      cutoff_date = @days_threshold.days.ago

      inactive_users = @studio.users.where(role: "customer").select do |user|
        last_checkin = user.check_ins.where(studio: @studio).maximum(:created_at)
        last_checkin.nil? || last_checkin < cutoff_date
      end

      {
        studio_name: @studio.name,
        threshold_days: @days_threshold,
        inactive_count: inactive_users.size,
        members: inactive_users.map do |user|
          last_checkin = user.check_ins.where(studio: @studio).maximum(:created_at)
          {
            id: user.id,
            name: "#{user.first_name} #{user.last_name}",
            email: user.email,
            last_check_in: last_checkin&.strftime("%Y-%m-%d") || "Never",
            days_since_last_visit: last_checkin ? ((Time.current - last_checkin) / 1.day).round : nil,
            total_check_ins: user.check_ins.where(studio: @studio).count
          }
        end
      }
    end
  end
end
