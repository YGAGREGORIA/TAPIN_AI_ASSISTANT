module AdminTools
  class Registry
    TOOLS = {
      "get_inactive_members" => AdminTools::GetInactiveMembers,
      "analyze_churn_risk" => AdminTools::AnalyzeChurnRisk,
      "get_member_insights" => AdminTools::GetMemberInsights,
      "suggest_deal" => AdminTools::SuggestDeal,
      "advise_loyalty_program" => AdminTools::AdviseLoyaltyProgram
    }.freeze

    def self.call(tool_name, studio:, **params)
      klass = TOOLS[tool_name]
      raise ArgumentError, "Unknown tool: #{tool_name}" unless klass

      klass.new(studio: studio, **params).call
    end

    def self.available_tools
      TOOLS.keys
    end

    def self.tool_definitions
      [
        {
          name: "get_inactive_members",
          description: "Get a list of studio members who haven't checked in recently",
          parameters: { days_threshold: { type: "integer", description: "Number of days of inactivity (default: 30)",
                                          required: false } }
        },
        {
          name: "analyze_churn_risk",
          description: "Analyze which members are at risk of leaving the studio",
          parameters: {}
        },
        {
          name: "get_member_insights",
          description: "Get detailed insights about a specific member, or find members close to earning rewards",
          parameters: { user_id: { type: "integer",
                                   description: "Specific member ID (optional - omit to see members close to rewards)", required: false } }
        },
        {
          name: "suggest_deal",
          description: "Get AI-suggested deals based on current member data and engagement patterns",
          parameters: {}
        },
        {
          name: "advise_loyalty_program",
          description: "Get advice on how to improve the studio's loyalty program based on current metrics",
          parameters: {}
        }
      ]
    end
  end
end
